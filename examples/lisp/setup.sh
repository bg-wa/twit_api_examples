#!/bin/bash

# Setup script for Common Lisp TWiT API client
# This script installs SBCL and Quicklisp locally and sets up the required packages

# Create local directory for SBCL and Quicklisp
mkdir -p ~/.local/share/twit-lisp
cd ~/.local/share/twit-lisp

echo "Setting up Common Lisp environment for TWiT API client..."

# Check if SBCL is already installed locally
if [ ! -f ~/.local/share/twit-lisp/bin/sbcl ]; then
    echo "Downloading and installing SBCL locally..."
    
    # Download SBCL binary
    curl -L -o sbcl.tar.bz2 http://prdownloads.sourceforge.net/sbcl/sbcl-2.2.6-x86-64-linux-binary.tar.bz2
    
    # Extract SBCL
    tar -xjf sbcl.tar.bz2
    cd sbcl-2.2.6-x86-64-linux
    
    # Install SBCL locally
    INSTALL_ROOT=~/.local/share/twit-lisp ./install.sh
    
    # Clean up
    cd ..
    rm -rf sbcl-2.2.6-x86-64-linux
    rm sbcl.tar.bz2
    
    echo "SBCL installed locally."
else
    echo "SBCL already installed locally."
fi

# Check if Quicklisp is already installed
if [ ! -f ~/.local/share/twit-lisp/quicklisp/setup.lisp ]; then
    echo "Downloading and installing Quicklisp..."
    
    # Download Quicklisp
    curl -L -o quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp
    
    # Install Quicklisp
    SBCL_HOME=~/.local/share/twit-lisp/lib/sbcl ~/.local/share/twit-lisp/bin/sbcl --noinform \
        --eval '(load "quicklisp.lisp")' \
        --eval '(quicklisp-quickstart:install :path "~/.local/share/twit-lisp/quicklisp/")' \
        --eval '(quit)'
    
    # Clean up
    rm quicklisp.lisp
    
    echo "Quicklisp installed."
else
    echo "Quicklisp already installed."
fi

# Install required packages
echo "Installing required packages..."
SBCL_HOME=~/.local/share/twit-lisp/lib/sbcl ~/.local/share/twit-lisp/bin/sbcl --noinform \
    --load ~/.local/share/twit-lisp/quicklisp/setup.lisp \
    --eval '(ql:quickload :dexador)' \
    --eval '(ql:quickload :jonathan)' \
    --eval '(ql:quickload :cl-ppcre)' \
    --eval '(ql:quickload :local-time)' \
    --eval '(ql:quickload :alexandria)' \
    --eval '(ql:quickload :str)' \
    --eval '(quit)'

echo "Required packages installed."

# Create wrapper script for running tests
cat > ~/.local/share/twit-lisp/run-twit-test.sh << 'EOF'
#!/bin/bash
# Wrapper script to run TWiT API tests with local SBCL and Quicklisp

if [ -z "$1" ]; then
    echo "Usage: $0 <lisp-file>"
    exit 1
fi

SBCL_HOME=~/.local/share/twit-lisp/lib/sbcl ~/.local/share/twit-lisp/bin/sbcl --noinform \
    --load ~/.local/share/twit-lisp/quicklisp/setup.lisp \
    --load "$1" \
    --quit
EOF

chmod +x ~/.local/share/twit-lisp/run-twit-test.sh

# Create symbolic link to the wrapper script in the current directory
ln -sf ~/.local/share/twit-lisp/run-twit-test.sh ./run-twit-test.sh

echo "Setup completed successfully!"
echo "You can now run the TWiT API client with: ./run-twit-test.sh demo-twit-api.lisp"
