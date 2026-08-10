#pragma once

#include <cassert>
#include <cstdlib>
#include <functional>
#include <memory>
#include <string>
#include <typeindex>
#include <utility>

#include <rosa/rosa.h>

#include <geometry_msgs/msg/Point32.h>
#include <geometry_msgs/msg/Point.h>
#include <geometry_msgs/msg/PointStamped.h>
#include <geometry_msgs/msg/PoseStamped.h>
#include <nav_msgs/msg/Odometry.h>
#include <nav_msgs/msg/Path.h>
#include <sensor_msgs/msg/Image.h>
#include <sensor_msgs/msg/Imu.h>
#include <sensor_msgs/msg/NavSatFix.h>
#include <sensor_msgs/msg/PointCloud.h>
#include <std_msgs/msg/Bool.h>
#include <std_msgs/msg/ColorRGBA.h>
#include <std_msgs/msg/Float32.h>
#include <std_msgs/msg/Header.h>
#include <visualization_msgs/msg/Marker.h>
#include <visualization_msgs/msg/MarkerArray.h>

namespace std_msgs {
using Header = msg::Header;
using Float32 = msg::Float32;
using Float32ConstPtr = msg::Float32::ConstSharedPtr;
using Bool = msg::Bool;
using BoolConstPtr = msg::Bool::ConstSharedPtr;
using ColorRGBA = msg::ColorRGBA;
}  // namespace std_msgs

namespace geometry_msgs {
using Point32 = msg::Point32;
using Point = msg::Point;
using PointStamped = msg::PointStamped;
using PoseStamped = msg::PoseStamped;
}  // namespace geometry_msgs

namespace nav_msgs {
using Odometry = msg::Odometry;
using OdometryConstPtr = msg::Odometry::ConstSharedPtr;
using Path = msg::Path;
}  // namespace nav_msgs

namespace sensor_msgs {
using Image = msg::Image;
using ImagePtr = msg::Image::SharedPtr;
using ImageConstPtr = msg::Image::ConstSharedPtr;
using Imu = msg::Imu;
using ImuConstPtr = msg::Imu::ConstSharedPtr;
using NavSatFix = msg::NavSatFix;
using NavSatFixConstPtr = msg::NavSatFix::ConstSharedPtr;
using PointCloud = msg::PointCloud;
using PointCloudConstPtr = msg::PointCloud::ConstSharedPtr;
using ChannelFloat32 = msg::ChannelFloat32;
}  // namespace sensor_msgs

namespace visualization_msgs {
using Marker = msg::Marker;
using MarkerArray = msg::MarkerArray;
}  // namespace visualization_msgs

namespace ros {
namespace detail {
inline std::string &nodeName()
{
    static std::string name = "rosa_node";
    return name;
}

inline rosa::Node::SharedPtr &nodeInstance()
{
    static rosa::Node::SharedPtr node;
    return node;
}
}  // namespace detail

class Time
{
public:
    Time() = default;
    explicit Time(double seconds) : value_(rosa::Time::fromSeconds(seconds)) {}
    Time(const builtin_interfaces::msg::Time &time) : value_(time) {}

    operator builtin_interfaces::msg::Time() const { return value_; }
    double toSec() const { return value_.seconds(); }

private:
    rosa::Time value_;
};

using Duration = rosa::Duration;

class Publisher
{
public:
    Publisher() = default;

    template <typename MessageT>
    explicit Publisher(std::shared_ptr<rosa::Writer<MessageT>> writer)
        : writer_(std::move(writer)),
          type_(typeid(MessageT)),
          write_([typed_writer = std::static_pointer_cast<rosa::Writer<MessageT>>(writer_)](const void *message) {
              typed_writer->write(*static_cast<const MessageT *>(message));
          })
    {
    }

    template <typename MessageT>
    void publish(const MessageT &message) const
    {
        if (!write_ || type_ != std::type_index(typeid(MessageT))) {
            ULOGE("Publisher message type mismatch");
            return;
        }
        write_(&message);
    }

    template <typename MessageT>
    void publish(const std::shared_ptr<MessageT> &message) const
    {
        if (message) publish(*message);
    }

private:
    std::shared_ptr<void> writer_;
    std::type_index type_{typeid(void)};
    std::function<void(const void *)> write_;
};

class Subscriber
{
public:
    Subscriber() = default;

    template <typename MessageT>
    explicit Subscriber(std::shared_ptr<rosa::Reader<MessageT>> reader) : reader_(std::move(reader)) {}

private:
    std::shared_ptr<void> reader_;
};

class TransportHints
{
public:
    TransportHints &tcpNoDelay() { return *this; }
};

class NodeHandle
{
public:
    explicit NodeHandle(const std::string &ns = "") : private_namespace_(ns == "~")
    {
        if (!detail::nodeInstance()) detail::nodeInstance() = rosa::Node::make_shared(detail::nodeName());
    }

    template <typename MessageT>
    Publisher advertise(const std::string &topic, size_t depth)
    {
        return Publisher(detail::nodeInstance()->createWriter<MessageT>(resolveName(topic), rosa::QoS(depth)));
    }

    template <typename MessageT, typename CallbackT>
    Subscriber subscribe(const std::string &topic, size_t depth, CallbackT &&callback,
                         const TransportHints & = TransportHints())
    {
        return Subscriber(detail::nodeInstance()->createReader<MessageT>(
            resolveName(topic), rosa::QoS(depth), std::forward<CallbackT>(callback)));
    }

    template <typename T>
    bool getParam(const std::string &, T &) const
    {
        return false;
    }

    rosa::Node &node() const { return *detail::nodeInstance(); }
    void shutdown() const { rosa::shutdown(); }

private:
    std::string resolveName(const std::string &topic) const
    {
        if (topic.empty() || topic.front() == '/' || !private_namespace_) return topic;
        return "/" + detail::nodeName() + "/" + topic;
    }

    bool private_namespace_ = false;
};

inline void init(int argc, char **argv, const std::string &node_name)
{
    detail::nodeName() = node_name;
    rosa::init(argc, argv);
}

inline void spin()
{
    rosa::multiSpin(detail::nodeInstance());
}

inline bool ok() { return rosa::ok(); }
inline void shutdown() { rosa::shutdown(); }

namespace console {
enum levels { Debug, Info, Warn, Error, Fatal };
inline bool set_logger_level(const std::string &, levels) { return true; }
}  // namespace console

namespace package {
inline std::string getPath(const std::string &package_name)
{
    return rosa::utils::expandPackagePath("%%" + package_name + "%%");
}
}  // namespace package
}  // namespace ros

#ifndef ROSCONSOLE_DEFAULT_NAME
#define ROSCONSOLE_DEFAULT_NAME "default"
#endif
#define ROS_DEBUG(...) ULOGD(__VA_ARGS__)
#define ROS_INFO(...) ULOGI(__VA_ARGS__)
#define ROS_WARN(...) ULOGW(__VA_ARGS__)
#define ROS_ERROR(...) ULOGE(__VA_ARGS__)
#define ROS_DEBUG_STREAM(message) ULOGD_S() << message
#define ROS_INFO_STREAM(message) ULOGI_S() << message
#define ROS_WARN_STREAM(message) ULOGW_S() << message
#define ROS_ERROR_STREAM(message) ULOGE_S() << message
#define ROS_ASSERT(condition) assert(condition)
#define ROS_BREAK() std::abort()
