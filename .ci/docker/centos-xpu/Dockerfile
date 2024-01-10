ARG CENTOS_VERSION

FROM quay.io/centos/centos:${CENTOS_VERSION}

ARG CENTOS_VERSION

# Install required packages to build Caffe2

# Install common dependencies (so that this step can be cached separately)
COPY ./common/install_base.sh install_base.sh
RUN bash ./install_base.sh && rm install_base.sh

# Update CentOS git version
RUN yum -y remove git
RUN yum -y remove git-*
RUN yum -y install https://packages.endpoint.com/rhel/7/os/x86_64/endpoint-repo-1.9-1.x86_64.rpm || \
    (yum -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo-1.9-1.x86_64.rpm && \
    sed -i "s/packages.endpoint/packages.endpointdev/" /etc/yum.repos.d/endpoint.repo)
RUN yum install -y git

# Install devtoolset
ARG DEVTOOLSET_VERSION
COPY ./common/install_devtoolset.sh install_devtoolset.sh
RUN bash ./install_devtoolset.sh && rm install_devtoolset.sh
ENV BASH_ENV "/etc/profile"

# (optional) Install non-default glibc version
ARG GLIBC_VERSION
COPY ./common/install_glibc.sh install_glibc.sh
RUN if [ -n "${GLIBC_VERSION}" ]; then bash ./install_glibc.sh; fi
RUN rm install_glibc.sh

# Install user
COPY ./common/install_user.sh install_user.sh
RUN bash ./install_user.sh && rm install_user.sh

# Install conda and other packages (e.g., numpy, pytest)
ARG ANACONDA_PYTHON_VERSION
ARG CONDA_CMAKE
ENV ANACONDA_PYTHON_VERSION=$ANACONDA_PYTHON_VERSION
ENV PATH /opt/conda/envs/py_$ANACONDA_PYTHON_VERSION/bin:/opt/conda/bin:$PATH
COPY requirements-ci.txt /opt/conda/requirements-ci.txt
COPY ./common/install_conda.sh install_conda.sh
COPY ./common/common_utils.sh common_utils.sh
RUN bash ./install_conda.sh && rm install_conda.sh common_utils.sh /opt/conda/requirements-ci.txt

# (optional) Install protobuf for ONNX
ARG PROTOBUF
COPY ./common/install_protobuf.sh install_protobuf.sh
RUN if [ -n "${PROTOBUF}" ]; then bash ./install_protobuf.sh; fi
RUN rm install_protobuf.sh
ENV INSTALLED_PROTOBUF ${PROTOBUF}

# (optional) Install database packages like LMDB and LevelDB
ARG DB
COPY ./common/install_db.sh install_db.sh
RUN if [ -n "${DB}" ]; then bash ./install_db.sh; fi
RUN rm install_db.sh
ENV INSTALLED_DB ${DB}

# (optional) Install vision packages like OpenCV and ffmpeg
ARG VISION
COPY ./common/install_vision.sh ./common/cache_vision_models.sh ./common/common_utils.sh ./
RUN if [ -n "${VISION}" ]; then bash ./install_vision.sh; fi
RUN rm install_vision.sh cache_vision_models.sh common_utils.sh
ENV INSTALLED_VISION ${VISION}

# Install XPU Dependencies
ARG BASEKIT_VERSION
COPY ./common/install_xpu.sh install_xpu.sh
RUN bash ./install_xpu.sh && rm install_xpu.sh

# (optional) Install non-default CMake version
ARG CMAKE_VERSION
COPY ./common/install_cmake.sh install_cmake.sh
RUN if [ -n "${CMAKE_VERSION}" ]; then bash ./install_cmake.sh; fi
RUN rm install_cmake.sh

# (optional) Install non-default Ninja version
ARG NINJA_VERSION
COPY ./common/install_ninja.sh install_ninja.sh
RUN if [ -n "${NINJA_VERSION}" ]; then bash ./install_ninja.sh; fi
RUN rm install_ninja.sh

ARG TRITON
# Install triton, this needs to be done before sccache because the latter will
# try to reach out to S3, which docker build runners don't have access
COPY ./common/install_triton.sh install_triton.sh
COPY ./common/common_utils.sh common_utils.sh
# TODO: will add triton xpu commit
COPY ci_commit_pins/triton.txt triton.txt
RUN if [ -n "${TRITON}" ]; then bash ./install_triton.sh; fi
RUN rm install_triton.sh common_utils.sh triton.txt

# Install ccache/sccache (do this last, so we get priority in PATH)
COPY ./common/install_cache.sh install_cache.sh
ENV PATH /opt/cache/bin:$PATH
RUN bash ./install_cache.sh && rm install_cache.sh

# Include BUILD_ENVIRONMENT environment variable in image
ARG BUILD_ENVIRONMENT
ENV BUILD_ENVIRONMENT ${BUILD_ENVIRONMENT}

USER jenkins
CMD ["bash"]
