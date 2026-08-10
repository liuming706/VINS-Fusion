cmake_minimum_required(VERSION 3.16)
project(loop_fusion)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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

add_executable(loop_fusion_node
  src/pose_graph_node.cpp
  src/pose_graph.cpp
  src/keyframe.cpp
  src/utility/CameraPoseVisualization.cpp
  src/ThirdParty/DBoW/BowVector.cpp
  src/ThirdParty/DBoW/FBrief.cpp
  src/ThirdParty/DBoW/FeatureVector.cpp
  src/ThirdParty/DBoW/QueryResults.cpp
  src/ThirdParty/DBoW/ScoringObject.cpp
  src/ThirdParty/DUtils/Random.cpp
  src/ThirdParty/DUtils/Timestamp.cpp
  src/ThirdParty/DVision/BRIEF.cpp
  src/ThirdParty/VocabularyBinary.cpp)
target_include_directories(loop_fusion_node PRIVATE
  src
  ../rosa_compat/include
  ${EIGEN3_INCLUDE_PARENT})
target_link_libraries(loop_fusion_node PRIVATE
  rosa::rosa
  std_msgs::std_msgs
  geometry_msgs::geometry_msgs
  nav_msgs::nav_msgs
  sensor_msgs::sensor_msgs
  visualization_msgs::visualization_msgs
  shm_msgs::shm_msgs
  cv_bridge::cv_bridge
  camera_models::camera_models
  Boost::boost
  ${OpenCV_LIBS}
  ${CERES_LIBRARIES}
  Eigen3::Eigen)
target_compile_options(loop_fusion_node PRIVATE -Wno-error=maybe-uninitialized)

install(TARGETS loop_fusion_node DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY ../support_files/ DESTINATION share/${PROJECT_NAME}/support_files)
ament_package()
