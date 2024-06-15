"""setup midea-local."""

import setuptools

with open("README.md", encoding="utf-8") as fh:
    long_description = fh.read()

requires = ["aiohttp", "ifaddr", "pycryptodome"]

setuptools.setup(
    name="midea-local",
    version="1.0.5",
    author="rokam",
    author_email="lucas@mindello.com.br",
    description="Control your Midea M-Smart appliances via local area network",
    license="MIT",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/rokam/midea-local",
    install_requires=requires,
    packages=setuptools.find_packages(
        include=["midealocal", "midealocal.*"],
        exclude=["tests", "tests.*"],
    ),
    python_requires=">=3.10",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
)
