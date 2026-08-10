cmake_minimum_required(VERSION 3.16)
project(camera_models)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(ament_cmake REQUIRED)
find_package(Boost REQUIRED COMPONENTS filesystem program_options system)
find_package(OpenCV REQUIRED)
find_package(Ceres REQUIRED)
find_package(Eigen3 REQUIRED)
get_target_property(EIGEN3_INCLUDE_DIRS Eigen3::Eigen INTERFACE_INCLUDE_DIRECTORIES)
list(GET EIGEN3_INCLUDE_DIRS 0 EIGEN3_INCLUDE_DIR)
get_filename_component(EIGEN3_INCLUDE_PARENT "${EIGEN3_INCLUDE_DIR}" DIRECTORY)

set(CAMERA_MODEL_SOURCES
  src/chessboard/Chessboard.cc
  src/calib/CameraCalibration.cc
  src/camera_models/Camera.cc
  src/camera_models/CameraFactory.cc
  src/camera_models/CostFunctionFactory.cc
  src/camera_models/PinholeCamera.cc
  src/camera_models/PinholeFullCamera.cc
  src/camera_models/CataCamera.cc
  src/camera_models/EquidistantCamera.cc
  src/camera_models/ScaramuzzaCamera.cc
  src/sparse_graph/Transform.cc
  src/gpl/gpl.cc
  src/gpl/EigenQuaternionParameterization.cc)

add_library(camera_models SHARED ${CAMERA_MODEL_SOURCES})
target_include_directories(camera_models PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
  PRIVATE ${EIGEN3_INCLUDE_PARENT})
target_link_libraries(camera_models PRIVATE ${Boost_LIBRARIES} ${OpenCV_LIBS} ${CERES_LIBRARIES})

add_executable(Calibrations src/intrinsic_calib.cc ${CAMERA_MODEL_SOURCES})
target_include_directories(Calibrations PRIVATE include ${EIGEN3_INCLUDE_PARENT})
target_link_libraries(Calibrations PRIVATE ${Boost_LIBRARIES} ${OpenCV_LIBS} ${CERES_LIBRARIES})

install(TARGETS camera_models Calibrations
  EXPORT camera_modelsTargets
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY include/ DESTINATION include)

ament_export_targets(camera_modelsTargets HAS_LIBRARY_TARGET)
ament_export_include_directories(include)
ament_export_libraries(camera_models)
ament_export_dependencies(Boost OpenCV Ceres)
ament_package()
