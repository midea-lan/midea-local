"""setup midea-local."""

from pathlib import Path

import setuptools

readme = Path("README.md")
with readme.open(encoding="utf-8") as fh:
    long_description = fh.read()

requirements = Path("requirements.txt")
with requirements.open(encoding="utf-8") as fp:
    requires = fp.read().splitlines()

setuptools.setup(
    name="midea-local",
    version="1.1.0",
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
    python_requires=">=3.11",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
)
