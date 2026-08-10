cmake_minimum_required(VERSION 3.16)
project(global_fusion)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ament_cmake REQUIRED)
find_package(rosa REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)
find_package(Ceres REQUIRED)
find_package(Eigen3 REQUIRED)
get_target_property(EIGEN3_INCLUDE_DIRS Eigen3::Eigen INTERFACE_INCLUDE_DIRECTORIES)
list(GET EIGEN3_INCLUDE_DIRS 0 EIGEN3_INCLUDE_DIR)
get_filename_component(EIGEN3_INCLUDE_PARENT "${EIGEN3_INCLUDE_DIR}" DIRECTORY)

add_subdirectory(ThirdParty/GeographicLib)

add_executable(global_fusion_node src/globalOptNode.cpp src/globalOpt.cpp)
target_include_directories(global_fusion_node PRIVATE
  src
  ../rosa_compat/include
  ThirdParty/GeographicLib/include
  ${EIGEN3_INCLUDE_PARENT})
target_link_libraries(global_fusion_node PRIVATE
  rosa::rosa
  std_msgs::std_msgs
  geometry_msgs::geometry_msgs
  nav_msgs::nav_msgs
  sensor_msgs::sensor_msgs
  visualization_msgs::visualization_msgs
  ${CERES_LIBRARIES}
  Eigen3::Eigen
  libGeographiccc)

install(TARGETS global_fusion_node DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY models/ DESTINATION share/${PROJECT_NAME}/models)
ament_package()
