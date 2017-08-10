# gpuDL-docker
Template structure for the Docker for the containing Python and R installations for GPU Deep Learning tests.

# Quickstart
```
git clone https://github.com/jdestefani/gpuDL-docker.git
cd gpuDL-docker
nvidia-docker run -it -v `pwd`/docker_volume:/root/shared_data -p #PORT#:8888 jdestefani/gpu_dl:latest
```

where ```#PORT#``` should be replaced with the port on which the default jupyter port (8888) should be redirected.

# How to verify that the Docker is working properly?
0. Make sure that [git](https://git-scm.com/) and [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) are installed. 
1. Run docker container in interactive mode (```-it``` cf. Quickstart)
2. Run following commands:
```
cd shared_data/samples
python keras_CNN_MNIST.py
Rscript keras_CNN_MNIST.R
```
