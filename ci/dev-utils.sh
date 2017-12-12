#! /bin/bash

set -e

sudo apt-get install -y --no-install-recommends \
    ca-certificates \
    make \
    git curl wget tar make \
    sqlite3 libsqlite3-dev \
    mysql-client libmysqlclient-dev \
    postgresql-9.3 postgresql-client-9.3 libpq-dev \
    jq realpath && \
    apt-get clean

sudo apt-get install -y --no-install-recommends python

export RUBY_INSTALL_VERSION=0.6.1
export CHRUBY_VERSION=0.3.9
export RUBY_VERSION=2.4.2
export GOLANG_VERSION=1.8.3

# Import Postmodern PGP key
 sudo wget -nv https://raw.github.com/postmodern/postmodern.github.io/master/postmodern.asc && \
   gpg --import postmodern.asc && \
   gpg --fingerprint 0xB9515E77 | grep 'Key fingerprint = 04B2 F3EA 6541 40BC C7DA  1B57 54C3 D9E9 B951 5E77' && \
   if [ "$?" != "0" ]; then echo "Invalid PGP key!"; exit 1; fi

# Install chruby
cd /tmp && \
    wget -nv -O chruby-$CHRUBY_VERSION.tar.gz https://github.com/postmodern/chruby/archive/v$CHRUBY_VERSION.tar.gz && \
    wget -nv https://raw.github.com/postmodern/chruby/master/pkg/chruby-$CHRUBY_VERSION.tar.gz.asc && \
    gpg --verify chruby-$CHRUBY_VERSION.tar.gz.asc chruby-$CHRUBY_VERSION.tar.gz && \
    tar -xzvf chruby-$CHRUBY_VERSION.tar.gz && \
   cd chruby-$CHRUBY_VERSION/ && \
    sudo ./scripts/setup.sh

# Install ruby-install
cd /tmp && \
   wget -nv -O ruby-install-$RUBY_INSTALL_VERSION.tar.gz https://github.com/postmodern/ruby-install/archive/v$RUBY_INSTALL_VERSION.tar.gz && \
   wget -nv https://raw.github.com/postmodern/ruby-install/master/pkg/ruby-install-$RUBY_INSTALL_VERSION.tar.gz.asc && \
   gpg --verify ruby-install-$RUBY_INSTALL_VERSION.tar.gz.asc ruby-install-$RUBY_INSTALL_VERSION.tar.gz && \
   tar -xzvf ruby-install-$RUBY_INSTALL_VERSION.tar.gz && \
  cd ruby-install-$RUBY_INSTALL_VERSION/ && \
   sudo make install

# Install Ruby
sudo ruby-install ruby $RUBY_VERSION -- --disable-install-rdoc

# Install Bundler
/bin/bash -l -c "                           \
  source /etc/profile.d/chruby.sh ;              \
  chruby $RUBY_VERSION ;                         \
  gem install bundler --no-ri --no-rdoc          \
"

# Install Golang
cd /tmp && \
     wget -nv https://storage.googleapis.com/golang/go$GOLANG_VERSION.linux-amd64.tar.gz && \
    ( \
        echo '1862f4c3d3907e59b04a757cfda0ea7aa9ef39274af99a784f5be843c80c6772 go1.8.3.linux-amd64.tar.gz' | \
        sha256sum -c - \
    ) && \
    sudo tar -C /usr/local -xzf go*.tar.gz

mkdir -p /opt/go
