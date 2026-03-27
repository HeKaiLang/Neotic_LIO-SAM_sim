# 1. 基础镜像
FROM osrf/ros:noetic-desktop-full

# 2. 彻底换源 (阿里云)
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 3. 安装必备工具及所有依赖 (以 root 身份运行)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:borglab/gtsam-release-4.0 -y && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ros-noetic-navigation \
    ros-noetic-robot-localization \
    ros-noetic-robot-state-publisher \
    ros-noetic-joint-state-publisher \
    ros-noetic-joint-state-publisher-gui \
    ros-noetic-xacro \
    ros-noetic-gazebo-ros-control \
    ros-noetic-ros-controllers \
    ros-noetic-teleop-twist-keyboard \
    libgtsam-dev libgtsam-unstable-dev \
    git \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# 4. 创建与 WSL 宿主机同权的非 root 用户 (关键所在)
# ==========================================
ARG USERNAME=calon
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# 切换到你的专属用户！接下来的所有操作都不再是 root
USER $USERNAME
ENV HOME=/home/$USERNAME

# ==========================================
# 5. 创建【专属算法工作空间】并编译 LIO-SAM
# ==========================================
WORKDIR $HOME/liosam_ws/src
RUN git clone https://github.com/TixiaoShan/LIO-SAM.git

# 填坑步骤：修复宏定义冲突与 C++14 报错 (注意路径全部变成了 $HOME)
RUN sed -i '/#include <opencv\/cv.h>/d' $HOME/liosam_ws/src/LIO-SAM/include/utility.h && \
    sed -i 's|#include <pcl/kdtree/kdtree_flann.h>|#include <pcl/kdtree/kdtree_flann.h>\n#include <opencv2/opencv.hpp>|g' $HOME/liosam_ws/src/LIO-SAM/include/utility.h

RUN sed -i 's/-std=c++11/-std=c++14/g' $HOME/liosam_ws/src/LIO-SAM/CMakeLists.txt

# 编译 LIO-SAM 的底层工作空间
WORKDIR $HOME/liosam_ws
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && catkin_make -j4"

# ==========================================
# 6. 环境配置 (将 liosam_ws 垫在最底层)
# ==========================================
RUN echo "source /opt/ros/noetic/setup.bash" >> $HOME/.bashrc
RUN echo "source $HOME/liosam_ws/devel/setup.bash" >> $HOME/.bashrc
# 注入 Gazebo 环境变量，确保能找到你以后写的 xacro 模型
RUN echo "export GAZEBO_MODEL_PATH=$HOME/catkin_ws/src:\$GAZEBO_MODEL_PATH" >> $HOME/.bashrc

RUN sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
    ros-noetic-velodyne-description \
    ros-noetic-velodyne-simulator \
    && sudo rm -rf /var/lib/apt/lists/*

# 默认进入你用于日常开发的 catkin_ws
WORKDIR $HOME/catkin_ws
CMD ["bash"]