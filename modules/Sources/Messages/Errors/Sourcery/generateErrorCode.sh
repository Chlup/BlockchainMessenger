#!/bin/zsh

#  MIT License
#
#  Copyright (c) 2023 Zcash
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in all
#  copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.

scriptDir=${0:a:h}
cd "${scriptDir}"

sourcery_version=2.0.3

if which sourcery >/dev/null; then
    if [[ $(sourcery --version) != $sourcery_version ]]; then
        echo "warning: Compatible sourcer version not installed. Install sourcer $sourcery_version. Currently installed version is $(sourcer --version)"
        exit 1
    fi

    sourcery \
        --disableCache \
        --parseDocumentation \
        --verbose \
        --sources ./ \
        --sources ../ \
        --templates MErrorCode.stencil \
        --output ../MErrorCode.swift

    sourcery \
        --disableCache \
        --parseDocumentation \
        --verbose \
        --sources ./ \
        --sources ../ \
        --templates MError.stencil \
        --output ../MError.swift

else
    echo "warning: sourcery not installed"
fi
