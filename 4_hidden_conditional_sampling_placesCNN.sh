#/bin/bash
#
# Anh Nguyen <anh.ng8@gmail.com>
# 2016

# Take in an unit number
if [ "$#" -ne "1" ]; then
  echo "Provide 1 output unit number e.g. 945 for bell pepper."
  exit 1
fi

opt_layer=fc6
act_layer=conv5
units="${1}"       # Index of neurons in fc layers or channels in conv layers
xy=6               # Spatial position for conv layers, for fc layers: xy = 0

n_iters=1000       # Run for N iterations
reset_every=100    # Reset the code every N iterations (for diversity)
save_every=10      # Save a sample every N iterations
lr=1 
lr_end=1          # Linearly decay toward this ending lr (e.g. for decaying toward 0, set lr_end = 1e-10)
threshold=0.98    # Filter out samples below this threshold e.g. 0.98

# -----------------------------------------------
# Multipliers in the update rule Eq.11 in the paper
# -----------------------------------------------
epsilon1=1e-7       # prior
epsilon2=1        # condition
epsilon3=1e-17    # noise
# -----------------------------------------------

init_file="None"    # Start from a random code

# Condition net
net_weights="nets/placesCNN/places205CNN_iter_300000.caffemodel"
net_definition="nets/placesCNN/places205CNN_deploy_updated.prototxt"
#-----------------------

# Output dir
output_dir="output/${act_layer}_chain_${units}_eps1_${epsilon1}_eps3_${epsilon3}"
mkdir -p ${output_dir}

# Directory to store samples
sample_dir=${output_dir}/samples
if [ "${save_every}" -gt "0" ]; then
    rm -rf ${sample_dir} 
    mkdir -p ${sample_dir} 
fi

for unit in ${units}; do
    unit_pad=`printf "%04d" ${unit}`

    for seed in {0..0}; do

        python ./sampling_class.py \
            --act_layer ${act_layer} \
            --opt_layer ${opt_layer} \
            --units ${unit} \
            --xy ${xy} \
            --n_iters ${n_iters} \
            --save_every ${save_every} \
            --reset_every ${reset_every} \
            --lr ${lr} \
            --lr_end ${lr_end} \
            --seed ${seed} \
            --output_dir ${output_dir} \
            --init_file ${init_file} \
            --epsilon1 ${epsilon1} \
            --epsilon2 ${epsilon2} \
            --epsilon3 ${epsilon3} \
            --threshold ${threshold} \
            --net_weights ${net_weights} \
            --net_definition ${net_definition} \

        # Plot the samples
        if [ "${save_every}" -gt "0" ]; then

            # Crop this image according to its receptive field size of conv5 units
            for f in ${sample_dir}/*.jpg; do 
                size=163
                offset=32
                convert $f -crop ${size}x${size}+${offset}+${offset} +repage $f           
            done

            f_chain=${output_dir}/chain_${units}_hx_${epsilon1}_noise_${epsilon3}__${seed}.jpg

            # Make a montage of steps
            montage `ls ${sample_dir}/*.jpg | shuf | head -30` -tile 10x -geometry +1+1 ${f_chain}
#            montage `ls ${sample_dir}/*.jpg` -tile 10x -geometry +1+1 ${f_chain}
      
            readlink -f ${f_chain}
        fi
    done
done
