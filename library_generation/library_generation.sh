#!/bin/bash -e

export BASE_PATH=/project/$MICROROS_LIBRARY_FOLDER

######## Init ########
source /opt/ros/$ROS_DISTRO/setup.bash
source install/local_setup.bash

ros2 run micro_ros_setup create_firmware_ws.sh generate_lib

######## Adding extra packages ########
pushd firmware/mcu_ws > /dev/null

    # Workaround: Copy just tf2_msgs
    git clone -b foxy https://github.com/ros2/geometry2
    cp -R geometry2/tf2_msgs ros2/tf2_msgs
    rm -rf geometry2

    # Import user defined packages
    mkdir extra_packages
    pushd extra_packages > /dev/null
        cp -R $BASE_PATH/library_generation/extra_packages/* .
        vcs import --input extra_packages.repos
    popd > /dev/null

popd > /dev/null

######## Build  ########
export TOOLCHAIN_PREFIX=/usr/bin/arm-none-eabi-
ros2 run micro_ros_setup build_firmware.sh $BASE_PATH/library_generation/toolchain.cmake $BASE_PATH/library_generation/colcon.meta

find firmware/build/include/ -name "*.c"  -delete
rm -rf $BASE_PATH/libmicroros
mkdir -p $BASE_PATH/libmicroros/include
cp -R firmware/build/include/* $BASE_PATH/libmicroros/include/ 
cp -R firmware/build/libmicroros.a $BASE_PATH/libmicroros/libmicroros.a
cp $BASE_PATH/library_generation/library.json $BASE_PATH/libmicroros/library.json

######## Generate extra files ########
find firmware/mcu_ws/ros2 \( -name "*.srv" -o -name "*.msg" -o -name "*.action" \) | awk -F"/" '{print $(NF-2)"/"$NF}' > $BASE_PATH/libmicroros/available_ros2_types
find firmware/mcu_ws/extra_packages \( -name "*.srv" -o -name "*.msg" -o -name "*.action" \) | awk -F"/" '{print $(NF-2)"/"$NF}' >> $BASE_PATH/libmicroros/available_ros2_types

cd firmware
echo "" > $BASE_PATH/libmicroros/built_packages
for f in $(find $(pwd) -name .git -type d); do pushd $f > /dev/null; echo $(git config --get remote.origin.url) $(git rev-parse HEAD) >> $BASE_PATH/libmicroros/built_packages; popd > /dev/null; done;
