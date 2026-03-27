# arm_helped_wifiCSI_signal_analysis

这个项目用于学习利用ros1 Neotic和Gazebo进行机器人LIO-SAM算法运行和MoveBase导航仿真。

本项目是在Win11上利用WSL2提供的Ubuntu20.04内核以及在Ubuntu20.04内运行的docker实现的。
Dockerfile和docker-compose.yml已经提供。

```
docker build -t noetic_lio_sim_gazebo_env .
```

```
docker compose up -d
docker exec -it lio_sam_sim bash
```

---
创建功能包：
```
catkin_create_pkg my_robot_description urdf xacro
catkin_create_pkg my_robot_gazebo gazebo_ros gazebo_plugins
catkin_create_pkg my_robot_slam roscpp std_msgs sensor_msgs
```
