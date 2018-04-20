# Download dataset
import urllib.request 
import os


def download_mnist(data_dir = "data"):
    mnist_file = f"{data_dir}/mnist.pkl.gz"
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)
    if not os.path.isfile(mnist_file):
        urllib.request.urlretrieve("https://github.com/mnielsen/neural-networks-and-deep-learning/raw/master/data/mnist.pkl.gz", mnist_file)
    