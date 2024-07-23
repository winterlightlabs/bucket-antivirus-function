FROM amazonlinux:2023

# Set up working directories
RUN mkdir -p /opt/app
RUN mkdir -p /opt/app/build
RUN mkdir -p /opt/app/bin/

# Copy in the lambda source
WORKDIR /opt/app
COPY ./*.py /opt/app/
COPY requirements.txt /opt/app/requirements.txt
COPY copylibs.sh /copylibs.sh

# Install packages
RUN yum update -y
RUN yum install -y cpio clamav clamav-update yum-utils tar.x86_64 gzip zip python3.11 python3.11-pip binutils

# This had --no-cache-dir, tracing through multiple tickets led to a problem in wheel
RUN pip3.11 install -r requirements.txt
RUN rm -rf /root/.cache/pip

# Copy over the binaries and libraries
RUN cp /bin/clamscan /usr/bin/freshclam /bin/ld /opt/app/bin/.

# Copy shared libraries required to run in lambda
RUN bash /copylibs.sh

# Fix the freshclam.conf settings
RUN echo "DatabaseMirror database.clamav.net" > /opt/app/bin/freshclam.conf
RUN echo "CompressLocalDatabase yes" >> /opt/app/bin/freshclam.conf
RUN echo "ScriptedUpdates no" >> /opt/app/bin/freshclam.conf
RUN echo "DatabaseDirectory /var/lib/clamav" >> /opt/app/bin/freshclam.conf

ENV LD_LIBRARY_PATH=/opt/app/bin
RUN ldconfig

# Create the zip file
WORKDIR /opt/app
RUN zip -r9 --exclude="*test*" /opt/app/build/lambda.zip *.py bin

WORKDIR /usr/local/lib/python3.11/site-packages
RUN zip -r9 /opt/app/build/lambda.zip *
