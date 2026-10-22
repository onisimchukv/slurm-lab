#!/bin/bash
#SBATCH --job-name=sweep
#SBATCH --array=1-20%5          # 20 tasks, at most 5 running at once
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH --output=sweep_%A_%a.out

# A toy parameter sweep: each array task gets its own parameter.
echo "task ${SLURM_ARRAY_TASK_ID} on $(hostname)"
sleep $(( (SLURM_ARRAY_TASK_ID % 5) + 5 ))
