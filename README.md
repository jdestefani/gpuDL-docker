# gpuDL-docker - Docker container for Deep Learning in R and Python with GPU support
 
This Dockerfile sets up a complete environment for experimenting with R, Python and  the most popular Deep Learning libraries (Tensorflow, Keras, Theano).

It installs:
* R 3.2.3 (r-base)
* Python 3.5
* Miniconda 3 
* Jupyter notebook for Python 

It additionally installs the following packages
### Python packages 
* h5py 
* pandas
* pygpu==0.6.2
* nose 
* mkl 
* six 
* pyyaml 
* keras==2.0.5 
* tensorflow-gpu==1.2.0 
* ipyparallel
* jupyter 
* matplotlib 
* seaborn 
* scikit-learn

### R Packages
* r-base-dev and [https://packages.ubuntu.com/xenial/r-recommended r-recommended] Ubuntu packages
* yhatr
* forecast
* stringr
* randomForest
* lubridate
* rpart
* e1071
* kknn
* ggplot2
* plyr
* reshape2
* devtools
* dse
* autoencoder
* pls
* MTS
* rnn
* feather
* data.table
* dplyr
* ranger
* zoo
* gbonte/gbcode (Github)
* rstudio/keras (Github)
* IRKernel/IRKernel (Github)

# Quickstart
```
git clone https://github.com/jdestefani/gpuDL-docker.git
cd gpuDL-docker
nvidia-docker run -it -v `pwd`/docker_volume:/root/shared_data -p #PORT#:8888 jdestefani/gpu_dl:latest
```

Note:

* **Important** The docker depends on [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) to access the underlying NVIDIA hardware. Running with regular docker will not allow to use GPU.
* The "-v `pwd`:/root/shared_data" shares the folder ```docker_volume``` on your computer (the 'host') with the container in the '/root/shared_data' folder
* Ports are shared as follows:
    * 8888 bridges to the Jupyter Notebook
* ```#PORT#``` should be replaced with the port on which the default jupyter port (8888) should be redirected.
* nvidia-docker

# Build and running the container from scratch

### Clone this repository

```
git clone https://github.com/jdestefani/gpuDL-docker.git
```

### Build

From Dockerfile folder, run

```
docker build -t gpu_dl .
```

It may take about 30 minutes to complete.

### Run

```
nvidia-docker run -it -v `pwd`/docker_volume:/root/shared_data -p #PORT#:8888 gpu_dl
```

# How to verify that the Docker is working properly?
0. Make sure that [git](https://git-scm.com/) and [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) are installed. 
1. Run docker container in interactive mode (```-it``` cf. Quickstart)
2. Run following commands:
```
cd shared_data/samples
python keras_CNN_MNIST.py
Rscript keras_CNN_MNIST.R
```












