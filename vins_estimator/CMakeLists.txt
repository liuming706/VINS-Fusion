cmake_minimum_required(VERSION 3.16)
project(vins)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(ament_cmake REQUIRED)
find_package(rosa REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(shm_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(camera_models REQUIRED)
find_package(OpenCV REQUIRED)
find_package(Ceres REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(Boost REQUIRED)
get_target_property(EIGEN3_INCLUDE_DIRS Eigen3::Eigen INTERFACE_INCLUDE_DIRECTORIES)
list(GET EIGEN3_INCLUDE_DIRS 0 EIGEN3_INCLUDE_DIR)
get_filename_component(EIGEN3_INCLUDE_PARENT "${EIGEN3_INCLUDE_DIR}" DIRECTORY)

set(VINS_ROSA_COMPAT ${CMAKE_CURRENT_SOURCE_DIR}/../rosa_compat/include)
set(VINS_DEPS
  rosa::rosa
  std_msgs::std_msgs
  geometry_msgs::geometry_msgs
  nav_msgs::nav_msgs
  sensor_msgs::sensor_msgs
  visualization_msgs::visualization_msgs
  shm_msgs::shm_msgs
  cv_bridge::cv_bridge
  camera_models::camera_models)

add_library(vins_lib SHARED
  src/estimator/parameters.cpp
  src/estimator/estimator.cpp
  src/estimator/feature_manager.cpp
  src/factor/pose_local_parameterization.cpp
  src/factor/projectionTwoFrameOneCamFactor.cpp
  src/factor/projectionTwoFrameTwoCamFactor.cpp
  src/factor/projectionOneFrameTwoCamFactor.cpp
  src/factor/marginalization_factor.cpp
  src/utility/utility.cpp
  src/utility/visualization.cpp
  src/utility/CameraPoseVisualization.cpp
  src/initial/solve_5pts.cpp
  src/initial/initial_aligment.cpp
  src/initial/initial_sfm.cpp
  src/initial/initial_ex_rotation.cpp
  src/featureTracker/feature_tracker.cpp)
target_include_directories(vins_lib PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
  $<BUILD_INTERFACE:${VINS_ROSA_COMPAT}>
  $<BUILD_INTERFACE:${EIGEN3_INCLUDE_PARENT}>
  $<INSTALL_INTERFACE:include>
)
target_link_libraries(vins_lib PUBLIC ${VINS_DEPS} ${OpenCV_LIBS} ${CERES_LIBRARIES} Eigen3::Eigen)
target_link_libraries(vins_lib PUBLIC Boost::boost)
target_compile_options(vins_lib PRIVATE -Wno-error=maybe-uninitialized)

add_executable(vins_node src/rosNodeTest.cpp)
target_link_libraries(vins_node PRIVATE vins_lib)

add_executable(kitti_odom_test src/KITTIOdomTest.cpp)
target_link_libraries(kitti_odom_test PRIVATE vins_lib)

add_executable(kitti_gps_test src/KITTIGPSTest.cpp)
target_link_libraries(kitti_gps_test PRIVATE vins_lib)

install(TARGETS vins_lib vins_node kitti_odom_test kitti_gps_test
  EXPORT vinsTargets
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY ${VINS_ROSA_COMPAT}/ DESTINATION include)

ament_export_targets(vinsTargets HAS_LIBRARY_TARGET)
ament_export_dependencies(rosa std_msgs geometry_msgs nav_msgs sensor_msgs visualization_msgs shm_msgs cv_bridge camera_models)
ament_package()
