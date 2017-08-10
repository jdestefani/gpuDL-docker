# Needs to specify THEANO_FLAGS="contexts=dev0->cuda0;dev1->cuda1" to use multiple GPUs
# Assuming GPU on the workstation are named cudaX, X \in {0,..,6}

import numpy
import theano

v01 = theano.shared(numpy.random.random((1024, 1024)).astype('float32'),
                    target='dev0')
v02 = theano.shared(numpy.random.random((1024, 1024)).astype('float32'),
                    target='dev0')
v11 = theano.shared(numpy.random.random((1024, 1024)).astype('float32'),
                    target='dev1')
v12 = theano.shared(numpy.random.random((1024, 1024)).astype('float32'),
                    target='dev1')

f = theano.function([], [theano.tensor.dot(v01, v02),
                         theano.tensor.dot(v11, v12)])

f()
