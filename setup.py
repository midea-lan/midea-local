"""setup midea-local."""

from pathlib import Path

import setuptools

readme = Path("README.md")
with readme.open(encoding="utf-8") as fh:
    long_description = fh.read()

requirements = Path("requirements.txt")
with requirements.open(encoding="utf-8") as fp:
    requires = fp.read().splitlines()

version: dict = {}
version_file = Path("midealocal", "version.py")
with version_file.open(encoding="utf-8") as fp:
    exec(fp.read(), version)  # noqa: S102


setuptools.setup(
    name="midea-local",
    version=version["__version__"],
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
    entry_points={
        "console_scripts": [
            "midealocal = midealocal.cli:main",
        ],
    },
    python_requires=">=3.11",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
)
