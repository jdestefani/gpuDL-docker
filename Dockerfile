FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04
#For CUDA compatibility: https://docs.nvidia.com/deploy/cuda-compatibility/index.html + nvidia-smi

ARG userPort=8888
ARG userName=jdestefa
ARG userGID=1002
ARG userID=1002

MAINTAINER Jacopo De Stefani <jdestefa@ulb.ac.be>

# Installing general purpose packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends --allow-change-held-packages \
      sudo \
      build-essential \
	  ed \
	  less \
	  curl \
	  git \
	  emacs-nox \
	  wget \
	  ca-certificates \
	  fonts-texgyre \
	  locales \
	  tmux \
	  htop \
	  xvfb \
	  libx11-dev \
	  libglu1-mesa-dev \
	  libfreetype6-dev \
	  libpng16-16 \
	  libcudnn8 \
	  && rm -rf /var/lib/apt/lists/*

#libcudnn7=7.2.1.38-1+cuda9.0 \
#--allow-downgrades libcudnn7=7.0.5.15-1+cuda9.0 \
	  

# Miniconda installation
RUN curl -qsSLkO \
    https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-`uname -p`.sh \
	&& bash Miniconda3-latest-Linux-`uname -p`.sh -b -p /opt/miniconda3 \
	&& rm Miniconda3-latest-Linux-`uname -p`.sh

ENV PATH=/opt/miniconda3/bin:$PATH

# Python
ARG python_version=3.7

# Update conda and creation of a python environment
# For Keras - Tensorflow pairings: https://docs.floydhub.com/guides/environments/
RUN conda update -n base conda && \
    	conda install -y python=${python_version} && \
	conda install -y \
    	h5py \
	pandas \
	pytables \
	pygpu \
	nose \
	mkl \
	six \
	pyyaml \
	jupyter \
	matplotlib \
	seaborn \
	scikit-learn\
	&& conda clean --yes --tarballs --packages --source-cache \
	&& pip install --upgrade -I setuptools \
	&& pip install --upgrade \
	keras==2.2.4 \
	tensorflow-gpu==1.13.1 \
	plotly \
	ipyparallel && ipcluster nbextension enable

# BLAS installation
RUN conda config --add channels conda-forge && \
    conda install blas && \
    conda clean -yt

# Theano Library paths - To check
ENV THEANO_FLAGS_CPU floatX=float32,device=cpu
ENV THEANO_FLAGS_GPU floatX=float32,device=gpu,dnn.enabled=False,gpuarray.preallocate=0.8
ENV THEANO_FLAGS_GPU_DNN floatX=float32,device=gpu,optimizer_including=cudnn,gpuarray.preallocate=0.8,dnn.conv.algo_bwd_filter=deterministic,dnn.conv.algo_bwd_data=deterministic,dnn.include_path=/usr/local/cuda/include,dnn.library_path=/usr/local/cuda/lib64

# CUDA configuration
ENV CUDA_HOME=/usr/local/cuda-10.0
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-10.0/lib64:/usr/local/cuda-10.0/lib64/stubs
ENV PATH=$PATH:/usr/local/cuda-10.0/bin
# Adding symlinks to comply with tensorflow library names

# Install scikit-cuda
RUN cd /root && \ 
	git clone https://github.com/lebedov/scikit-cuda && \
	cd scikit-cuda && \
	python setup.py install && \
	cd / \

## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# R installation

# Manually add R repository to list of sources to have R latest version
RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/" >> /etc/apt/sources.list \
&& gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-key E298A3A825C0D65DFD57CBB651716619E084DAB9 \
&& gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | apt-key add -
##&& apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/Brussels"

## Now install R and littler, and create a link for littler in /usr/local/bin
## Also set a default CRAN repo, and make sure littler knows about it too
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		libssl-dev \
		libcurl4-openssl-dev \
		littler \
        	r-cran-littler \
		r-base \
		r-base-dev \
		r-recommended \
        && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
        && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
	&& ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
	&& rm -rf /var/lib/apt/lists/*

RUN Rscript -e "install.packages(c('yhatr','forecast','stringr','randomForest','lubridate','rpart','e1071','kknn','ggplot2','plyr','reshape2','devtools'))"
RUN Rscript -e "install.packages(c('devtools'))"
RUN Rscript -e "library(devtools); install_version('mvtnorm', version ='1.0-7', repos = 'http://cran.us.r-project.org')"
RUN Rscript -e "library(devtools); install_github('gbonte/gbcode')"
RUN Rscript -e "library(devtools); install_github('rstudio/keras@2.2.4.1')"
RUN Rscript -e "library(devtools); install_github('vqv/ggbiplot')"
RUN Rscript -e "install.packages(c('dse','autoencoder','pls','MTS','rnn','feather','data.table','dplyr','ranger','zoo','plotly','gmatrix','HiPLARM', 'HiPLARb','Rssa','psych','kerasR','Rtsne','ggrepel','pryr'))"
RUN Rscript -e "install.packages(c('tsfeatures','RcppCNPy','TSclust','imputeTS','parallelDist','onlinePCA','xgboost','parallel','lightgbm'))"
RUN Rscript -e "library(devtools); install_github('IRkernel/IRkernel');"

# Manual installation of gputools and patching of gputools
RUN curl -O http://cran.r-project.org/src/contrib/Archive/gputools/gputools_1.1.tar.gz && \
    tar -zxvf gputools_1.1.tar.gz && \
    cd gputools && sed -i -e 's/R_INCLUDE="${R_HOME}\/include"/R_INCLUDE="\/usr\/share\/R\/include"/g' configure && cd .. && \
    tar -czvf gputools_1.1.tar.gz gputools && rm -rf gputools && \
    Rscript -e "install.packages('gputools_1.1.tar.gz', repos = NULL, type = 'source')"

# Create user in order to avoid running the container as root
RUN groupadd -g $userGID $userName
RUN useradd -u $userID -d /home/$userName -ms /bin/bash -g $userGID -G sudo,$userName -p $(openssl passwd -1 abc123) $userName
USER $userName
WORKDIR /home/$userName
ENV PATH=/opt/miniconda3/bin:$PATH
RUN echo "alias notebook=\"jupyter notebook --ip='0.0.0.0' --NotebookApp.iopub_data_rate_limit=2147483647 --no-browser \" " >> /home/$userName/.bashrc
RUN Rscript -e "IRkernel::installspec()"

# Theano Library paths - To check
ENV THEANO_FLAGS_CPU floatX=float32,device=cpu
ENV THEANO_FLAGS_GPU floatX=float32,device=gpu,dnn.enabled=False,gpuarray.preallocate=0.8
ENV THEANO_FLAGS_GPU_DNN floatX=float32,device=gpu,optimizer_including=cudnn,gpuarray.preallocate=0.8,dnn.conv.algo_bwd_filter=deterministic,dnn.conv.algo_bwd_data=deterministic,dnn.include_path=/usr/local/cuda/include,dnn.library_path=/usr/local/cuda/lib64

# Add volume to allow data exchange with the host machine
RUN mkdir /home/$userName/shared_data
VOLUME /home/$userName/shared_data
EXPOSE $userPort
#CMD jupyter notebook --no-browser --ip=0.0.0.0
