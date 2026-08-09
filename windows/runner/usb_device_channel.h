#ifndef RUNNER_USB_DEVICE_CHANNEL_H_
#define RUNNER_USB_DEVICE_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

class UsbDeviceChannel {
 public:
  explicit UsbDeviceChannel(flutter::BinaryMessenger* messenger);
  ~UsbDeviceChannel();

 private:
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_USB_DEVICE_CHANNEL_H_
