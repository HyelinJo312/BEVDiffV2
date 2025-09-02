#!/usr/bin/env bash

export CUDA_VISIBLE_DEVICES=0,1,2,3

GPUS=$1
PORT=${PORT:-29503}

BEV_CONFIG="../configs/bevdiffuser/layout_tiny.py"
# BEV_CHECKPOINT="../../ckpts/bevformer_tiny_epoch_24.pth"
BEV_CHECKPOINT=None
PRETRAINED_MODEL="stabilityai/stable-diffusion-2-1"
PRETRAINED_UNET_CHECKPOINT=None

# set up wandb project
PROJ_NAME=BEVDiffuser
RUN_NAME=BEVDiffuser_BEVFormer_tiny_scratch_non-fusion_customlr

# checkpoint settings
CHECKPOINT_STEP=10000
CHECKPOINT_LIMIT=20

# allow 500 extra steps to be safe
MAX_TRAINING_STEPS=40000
TRAIN_BATCH_SIZE=2
DATALOADER_NUM_WORKERS=2
GRADIENT_ACCUMMULATION_STEPS=1
NUM_TRAIN_EPOCHS=24

# loss and lr settings
LEARNING_RATE=1e-4  
BEV_LEARNING_RATE=2e-5
LR_SCHEDULER="constant" # cyclic, cosine, constant

UNCOND_PROB=0.2
PREDICTION_TYPE="sample" # "sample", "epsilon" or "v_prediction"
TASK_LOSS_SCALE=0.1 # 0.1

OUTPUT_DIR="../../../results/${RUN_NAME}"

mkdir -p $OUTPUT_DIR

export NCCL_SOCKET_IFNAME=lo
export NCCL_P2P_DISABLE=1
# export NCCL_IB_DISABLE=1
# export NCCL_SHM_DISABLE=1
export NCCL_DEBUG=INFO
export NCCL_ASYNC_ERROR_HANDLING=1
# export PYTHONWARNINGS="ignore"
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128

# train!
PYTHONPATH="$(dirname $0)/../..":$PYTHONPATH \
# python -m torch.distributed.launch --nproc_per_node=$GPUS --master_port=$PORT \
torchrun --nproc_per_node=4 --master_port=29505 \
  $(dirname "$0")/train_bev_diffuser_v2.py \
    --bev_config $BEV_CONFIG \
    --bev_checkpoint $BEV_CHECKPOINT \
    --pretrained_unet_checkpoint $PRETRAINED_UNET_CHECKPOINT \
    --pretrained_model_name_or_path $PRETRAINED_MODEL \
    --train_batch_size $TRAIN_BATCH_SIZE \
    --num_train_epochs $NUM_TRAIN_EPOCHS \
    --dataloader_num_workers $DATALOADER_NUM_WORKERS \
    --gradient_accumulation_steps $GRADIENT_ACCUMMULATION_STEPS \
    --max_train_steps $MAX_TRAINING_STEPS \
    --learning_rate $LEARNING_RATE \
    --bev_learning_rate $BEV_LEARNING_RATE \
    --lr_scheduler $LR_SCHEDULER \
    --output_dir $OUTPUT_DIR \
    --checkpoints_total_limit $CHECKPOINT_LIMIT \
    --checkpointing_steps $CHECKPOINT_STEP \
    --tracker_run_name $RUN_NAME \
    --tracker_project_name $PROJ_NAME \
    --uncond_prob $UNCOND_PROB \
    --prediction_type $PREDICTION_TYPE \
    --task_loss_scale $TASK_LOSS_SCALE \
    --report_to 'tensorboard' \
    # --gradient_checkpointing \


