FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

MAINTAINER Jacopo De Stefani <jdestefa@ulb.ac.be>

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
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
	  --allow-downgrades libcudnn7=7.0.5.15-1+cuda9.0 \
	  && rm -rf /var/lib/apt/lists/*

# Miniconda installation
RUN curl -qsSLkO \
    https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-`uname -p`.sh \
	&& bash Miniconda3-latest-Linux-`uname -p`.sh -b \
	&& rm Miniconda3-latest-Linux-`uname -p`.sh

ENV PATH=/root/miniconda3/bin:$PATH

# Python
ARG python_version=3.6

# Creation of a python environment
RUN conda update -n base conda && \
    	conda install -y python=${python_version} && \
	conda install -y \
    	h5py \
	pandas \
	pygpu==0.6.2 \
	nose \
	mkl \
	six \
	pyyaml \
	jupyter \
	matplotlib \
	seaborn \
	scikit-learn \
	&& conda clean --yes --tarballs --packages --source-cache \
	&& pip install --upgrade -I setuptools \
	&& pip install --upgrade \
	keras==2.1.5 \
	tensorflow-gpu==1.5.0 \
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
ENV CUDA_HOME=/usr/local/cuda-9.0
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-9.0/lib64:/usr/local/cuda-9.0/lib64/stubs
ENV PATH=$PATH:/usr/local/cuda-9.0/bin

# Symlink to existing library to comply with Tensorflow library names
#RUN ln -s /usr/local/cuda-9.0/lib64/stubs/libcuda.so /usr/local/cuda-9.0/lib64/stubs/libcuda.so.1

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
RUN Rscript -e "library(devtools); install_github('gbonte/gbcode')"
RUN Rscript -e "library(devtools); install_github('rstudio/keras')"
RUN Rscript -e "library(devtools); install_github('IRkernel/IRkernel'); IRkernel::installspec()"
RUN Rscript -e "install.packages(c('dse','autoencoder','pls','MTS','rnn','feather','data.table','dplyr','ranger','zoo','plotly','gmatrix','HiPLARM', 'HiPLARb'))"

# Manual installation of gputools and patching of gputools
RUN curl -O http://cran.r-project.org/src/contrib/Archive/gputools/gputools_1.1.tar.gz && \
    tar -zxvf gputools_1.1.tar.gz && \
    cd gputools && sed -i -e 's/R_INCLUDE="${R_HOME}\/include"/R_INCLUDE="\/usr\/share\/R\/include"/g' configure && cd .. && \
    tar -czvf gputools_1.1.tar.gz gputools && rm -rf gputools && \
    Rscript -e "install.packages('gputools_1.1.tar.gz', repos = NULL, type = 'source')"

# Add volume to allow data exchange with the host machine
RUN mkdir /root/shared_data
VOLUME /root/shared_data
WORKDIR /root
EXPOSE 8888
ENV JUPYTER_CONFIG_PATH=/root/shared_data/.config
