#!/bin/bash
#SBATCH --job-name=gpu-demo
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --qos=gpu_short
#SBATCH --time=00:10:00
#SBATCH --output=gpu_%j.out

# With simulated GPUs this only exercises scheduling and accounting.
# On real NVIDIA nodes, nvidia-smi would show the allocated device.
echo "host: $(hostname)"
echo "GPUs allocated: ${SLURM_GPUS_ON_NODE:-unknown}"
scontrol show job "$SLURM_JOB_ID" | grep -E 'TresPerNode|AllocTRES|TRES='
sleep 60
