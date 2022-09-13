# MANTA Documentation

The document describes the how to build and use MANTA’s static analysis tool to detect missing-account bugs for Linux kernel. The tool is the artifact of the paper “Making Memory Account Accountable: Analyzing and Detecting Memory Missing-account bugs for Container Platforms” published on ACSAC'22.

# Use MANTA

```bash
docker pull nglaive/manta-runner:latest
docker run -ti nglaive/manta-runner:latest /bin/bash
./run-manta.sh
# wait for a few minutes ...
# Display "MANTA analyzer for Linux missing-account bugs."
```

After invoking run-manta.sh, you need around 30-60 minutes to wait for the analysis to finish. When the analysis finishes, it prompts all the allocators are analyzed. It also reports a crash due to incompatible IR format, which can be *ignored*. The analysis results are included in the file *bughunt-result.txt*.

The result includes many sites that are unreachable from syscalls. To filter these ones and format the result, run the following command in the container.

```bash
python3 format-result.py
```

The final results are in the file *result.txt*.

# Result Format

Each item includes a missing account position followed by possible paths reaching syscall entries. BugLocation follows the LLVM output conventions for code location metadata. Each path in Paths starts from the buggy site and ends by a syscall.

```
Unaccounted allocation site: [BugLocation]
Unaccounted paths found:
[Paths]
```

# Build MANTA Container from Scratch

The container image manta-runner can be built from scratch following these steps:

1. Environment: Ubuntu 20.04 with git and docker installed. We recommend reserving 40GB disk space, 8GB memory, and at least 4 cores for MANTA container building.
2. Pull the building directory from this repo.

```bash
git clone https://github.com/ZJU-SEC/MANTA.git
cd MANTA
```

Note that *manta-src.tar.gz* contains MANTA’s source code.

3. Build the docker image. This step may take around an hour, as it includes compilation of LLVM, Linux kernel bitcode, and MANTA.

```bash
docker build -t manta-runner .
```
