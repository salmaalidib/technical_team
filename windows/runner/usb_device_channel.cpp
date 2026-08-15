#include "usb_device_channel.h"

#include <windows.h>
#include <setupapi.h>
#include <winioctl.h>
#include <ntddstor.h>

#include <algorithm>
#include <cctype>
#include <optional>
#include <string>
#include <vector>

#include "utils.h"

namespace {

struct StorageIdentity {
  std::string serial;
  std::string pnp_device_id;
  std::string vendor_id;
  std::string product_id;
};

std::string TrimAscii(std::string value) {
  const auto not_space = [](unsigned char character) {
    return !std::isspace(character);
  };
  value.erase(value.begin(),
              std::find_if(value.begin(), value.end(), not_space));
  value.erase(std::find_if(value.rbegin(), value.rend(), not_space).base(),
              value.end());
  return value;
}

std::string UpperAscii(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](unsigned char character) {
                   return static_cast<char>(std::toupper(character));
                 });
  return value;
}

std::string ExtractUsbToken(const std::string& pnp_id,
                            const std::string& prefix) {
  const auto upper = UpperAscii(pnp_id);
  const auto position = upper.find(prefix);
  if (position == std::string::npos || position + prefix.size() + 4 > upper.size()) {
    return "";
  }
  return upper.substr(position + prefix.size(), 4);
}

std::optional<DWORD> GetStorageDeviceNumber(HANDLE handle) {
  STORAGE_DEVICE_NUMBER number{};
  DWORD bytes_returned = 0;
  if (!DeviceIoControl(handle, IOCTL_STORAGE_GET_DEVICE_NUMBER, nullptr, 0,
                       &number, sizeof(number), &bytes_returned, nullptr)) {
    return std::nullopt;
  }
  return number.DeviceNumber;
}

std::string QuerySerial(HANDLE handle) {
  STORAGE_PROPERTY_QUERY query{};
  query.PropertyId = StorageDeviceProperty;
  query.QueryType = PropertyStandardQuery;

  STORAGE_DESCRIPTOR_HEADER header{};
  DWORD bytes_returned = 0;
  if (!DeviceIoControl(handle, IOCTL_STORAGE_QUERY_PROPERTY, &query,
                       sizeof(query), &header, sizeof(header), &bytes_returned,
                       nullptr) ||
      header.Size < sizeof(STORAGE_DEVICE_DESCRIPTOR)) {
    return "";
  }

  std::vector<BYTE> buffer(header.Size);
  if (!DeviceIoControl(handle, IOCTL_STORAGE_QUERY_PROPERTY, &query,
                       sizeof(query), buffer.data(),
                       static_cast<DWORD>(buffer.size()), &bytes_returned,
                       nullptr)) {
    return "";
  }

  const auto* descriptor =
      reinterpret_cast<const STORAGE_DEVICE_DESCRIPTOR*>(buffer.data());
  if (descriptor->SerialNumberOffset == 0 ||
      descriptor->SerialNumberOffset >= buffer.size()) {
    return "";
  }
  const auto* serial = reinterpret_cast<const char*>(
      buffer.data() + descriptor->SerialNumberOffset);
  const auto max_length = buffer.size() - descriptor->SerialNumberOffset;
  const auto length = strnlen_s(serial, max_length);
  return TrimAscii(std::string(serial, length));
}

StorageIdentity FindDiskIdentity(DWORD target_device_number) {
  StorageIdentity identity;
  HDEVINFO device_info = SetupDiGetClassDevsW(
      &GUID_DEVINTERFACE_DISK, nullptr, nullptr,
      DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
  if (device_info == INVALID_HANDLE_VALUE) return identity;

  for (DWORD index = 0;; ++index) {
    SP_DEVICE_INTERFACE_DATA interface_data{};
    interface_data.cbSize = sizeof(interface_data);
    if (!SetupDiEnumDeviceInterfaces(device_info, nullptr,
                                     &GUID_DEVINTERFACE_DISK, index,
                                     &interface_data)) {
      break;
    }

    DWORD required_size = 0;
    SetupDiGetDeviceInterfaceDetailW(device_info, &interface_data, nullptr, 0,
                                     &required_size, nullptr);
    if (required_size == 0) continue;

    std::vector<BYTE> detail_buffer(required_size);
    auto* detail = reinterpret_cast<SP_DEVICE_INTERFACE_DETAIL_DATA_W*>(
        detail_buffer.data());
    detail->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_W);
    SP_DEVINFO_DATA dev_info_data{};
    dev_info_data.cbSize = sizeof(dev_info_data);

    if (!SetupDiGetDeviceInterfaceDetailW(
            device_info, &interface_data, detail, required_size, nullptr,
            &dev_info_data)) {
      continue;
    }

    HANDLE disk = CreateFileW(detail->DevicePath, 0,
                              FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                              OPEN_EXISTING, 0, nullptr);
    if (disk == INVALID_HANDLE_VALUE) continue;

    const auto device_number = GetStorageDeviceNumber(disk);
    if (device_number && *device_number == target_device_number) {
      identity.serial = QuerySerial(disk);

      DWORD id_size = 0;
      SetupDiGetDeviceInstanceIdW(device_info, &dev_info_data, nullptr, 0,
                                  &id_size);
      if (id_size > 0) {
        std::vector<wchar_t> id_buffer(id_size);
        if (SetupDiGetDeviceInstanceIdW(device_info, &dev_info_data,
                                        id_buffer.data(), id_size, nullptr)) {
          identity.pnp_device_id = Utf8FromUtf16(id_buffer.data());
          identity.vendor_id = ExtractUsbToken(identity.pnp_device_id, "VID_");
          identity.product_id = ExtractUsbToken(identity.pnp_device_id, "PID_");
        }
      }
      CloseHandle(disk);
      break;
    }
    CloseHandle(disk);
  }

  SetupDiDestroyDeviceInfoList(device_info);
  return identity;
}

flutter::EncodableList EnumerateRemovableUsbDevices() {
  DWORD required_length = GetLogicalDriveStringsW(0, nullptr);
  if (required_length == 0) return {};

  std::vector<wchar_t> drives(required_length + 1);
  if (GetLogicalDriveStringsW(static_cast<DWORD>(drives.size()),
                              drives.data()) == 0) {
    return {};
  }

  flutter::EncodableList result;
  for (const wchar_t* root = drives.data(); *root != L'\0';
       root += wcslen(root) + 1) {
    if (GetDriveTypeW(root) != DRIVE_REMOVABLE) continue;

    std::wstring root_path(root);
    std::wstring volume_path = L"\\\\.\\" + root_path.substr(0, 2);
    HANDLE volume = CreateFileW(volume_path.c_str(), 0,
                                FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                                OPEN_EXISTING, 0, nullptr);

    StorageIdentity identity;
    if (volume != INVALID_HANDLE_VALUE) {
      const auto device_number = GetStorageDeviceNumber(volume);
      if (device_number) identity = FindDiskIdentity(*device_number);
      if (identity.serial.empty()) identity.serial = QuerySerial(volume);
      CloseHandle(volume);
    }

    wchar_t volume_label[MAX_PATH + 1]{};
    GetVolumeInformationW(root, volume_label, MAX_PATH + 1, nullptr, nullptr,
                          nullptr, nullptr, 0);

    ULARGE_INTEGER free_bytes{};
    ULARGE_INTEGER total_bytes{};
    ULARGE_INTEGER total_free_bytes{};
    GetDiskFreeSpaceExW(root, &free_bytes, &total_bytes, &total_free_bytes);

    flutter::EncodableMap item;
    item[flutter::EncodableValue("driveLetter")] = flutter::EncodableValue(
        Utf8FromUtf16(root_path.substr(0, 2).c_str()));
    item[flutter::EncodableValue("rootPath")] =
        flutter::EncodableValue(Utf8FromUtf16(root));
    item[flutter::EncodableValue("volumeLabel")] =
        flutter::EncodableValue(Utf8FromUtf16(volume_label));
    item[flutter::EncodableValue("physicalSerialNumber")] =
        flutter::EncodableValue(identity.serial);
    item[flutter::EncodableValue("pnpDeviceId")] =
        flutter::EncodableValue(identity.pnp_device_id);
    item[flutter::EncodableValue("vendorId")] =
        flutter::EncodableValue(identity.vendor_id);
    item[flutter::EncodableValue("productId")] =
        flutter::EncodableValue(identity.product_id);
    item[flutter::EncodableValue("isRemovable")] =
        flutter::EncodableValue(true);
    item[flutter::EncodableValue("totalBytes")] = flutter::EncodableValue(
        static_cast<int64_t>(total_bytes.QuadPart));
    item[flutter::EncodableValue("freeBytes")] = flutter::EncodableValue(
        static_cast<int64_t>(free_bytes.QuadPart));
    result.emplace_back(item);
  }
  return result;
}

}  // namespace

UsbDeviceChannel::UsbDeviceChannel(flutter::BinaryMessenger* messenger) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "technical_team/usb_devices",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [](const auto& call, auto result) {
        if (call.method_name() == "getConnectedUsbDevices") {
          result->Success(flutter::EncodableValue(EnumerateRemovableUsbDevices()));
          return;
        }
        result->NotImplemented();
      });
}

UsbDeviceChannel::~UsbDeviceChannel() = default;
