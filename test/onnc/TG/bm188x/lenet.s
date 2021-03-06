# RUN: onnx-as %s | onnx2tg -march bm1880 -print-module-before-isel -add-dummy-weight -o=- | FileCheck %s

# CHECK: FLOAT tensor <1, 20, 24, 24> %conv1_1 = Conv <pads:INTS [0,0,0,0], strides:INTS [1,1], kernel_shape:INTS [5,5]> (FLOAT tensor <1, 1, 28, 28> %data_0, FLOAT tensor <20, 1, 5, 5> %conv1_w_0, FLOAT tensor <20> %conv1_b_0)
# CHECK: FLOAT tensor <1, 20, 12, 12> %pool1_1 = MaxPool <pads:INTS [0,0,1,1], kernel_shape:INTS [2,2], strides:INTS [2,2]> (FLOAT tensor <1, 20, 24, 24> %conv1_1)
# CHECK: FLOAT tensor <1, 50, 8, 8> %conv2_1 = Conv <pads:INTS [0,0,0,0], strides:INTS [1,1], kernel_shape:INTS [5,5]> (FLOAT tensor <1, 20, 12, 12> %pool1_1, FLOAT tensor <50, 20, 5, 5> %conv2_w_0, FLOAT tensor <50> %conv2_b_0)
# CHECK: FLOAT tensor <1, 50, 4, 4> %pool2_1 = MaxPool <pads:INTS [0,0,1,1], kernel_shape:INTS [2,2], strides:INTS [2,2]> (FLOAT tensor <1, 50, 8, 8> %conv2_1)
# CHECK: FLOAT tensor <1, 800> %OC2_DUMMY_0 = Reshape(FLOAT tensor <1, 50, 4, 4> %pool2_1, INT64 tensor <2> %OC2_DUMMY_1)
# CHECK: FLOAT tensor <1, 500> %relu1_1 = Gemm <transB:INT 1, broadcast:INT 1, do_relu:INT 1> (FLOAT tensor <1, 800> %OC2_DUMMY_0, FLOAT tensor <500, 800> %ip1_w_0, FLOAT tensor <500> %ip1_b_0)
# CHECK: FLOAT tensor <1, 10> %ip2_1 = Gemm <transB:INT 1, broadcast:INT 1> (FLOAT tensor <1, 500> %relu1_1, FLOAT tensor <10, 500> %ip2_w_0, FLOAT tensor <10> %ip2_b_0)
# CHECK: FLOAT tensor <1, 10> %prob_1 = Softmax(FLOAT tensor <1, 10> %ip2_1)

# CHECK: inst {
# CHECK-NEXT:   name: "conv1_1"
# CHECK-NEXT:   type: "bmnet_conv_parallel_fixed_forward_bmkernel"
# CHECK-NEXT:   conv_p {
# CHECK-NEXT:     ga_ifmap: 0
# CHECK-NEXT:     ga_ofmap: {{.*}}
# CHECK-NEXT:     ga_weight: 0
# CHECK-NEXT:     ga_bias: {{.*}}
# CHECK-NEXT:     ga_bn_mean: 1099511627775
# CHECK-NEXT:     ga_bn_variance: 1099511627775
# CHECK-NEXT:     ga_scale: 1099511627775
# CHECK-NEXT:     ga_scale_bias: 1099511627775
# CHECK-NEXT:     input_n: 1
# CHECK-NEXT:     input_c: 1
# CHECK-NEXT:     input_h: 28
# CHECK-NEXT:     input_w: 28
# CHECK-NEXT:     groups: 1
# CHECK-NEXT:     output_c: 20
# CHECK-NEXT:     kh: 5
# CHECK-NEXT:     kw: 5
# CHECK-NEXT:     dilation_h: 1
# CHECK-NEXT:     dilation_w: 1
# CHECK-NEXT:     pad_h: 0
# CHECK-NEXT:     pad_w: 0
# CHECK-NEXT:     stride_h: 1
# CHECK-NEXT:     stride_w: 1
# CHECK-NEXT:     result_add: 0
# CHECK-NEXT:     do_bias: 1
# CHECK-NEXT:     do_bn: 0
# CHECK-NEXT:     do_scale: 0
# CHECK-NEXT:     do_scale_bias: 0
# CHECK-NEXT:     do_activation: 0
# CHECK-NEXT:     bn_scale: 0
# CHECK-NEXT:     bn_eps: 0
# CHECK-NEXT:     activation_method: 0
# CHECK-NEXT:     activation_arg: 0
# CHECK-NEXT:     activation_ga_slope: 0
# CHECK-NEXT:     activation_channel_shared: false
# CHECK-NEXT:     activation_gt_scale: 0
# CHECK-NEXT:     activation_gt_rshift: 0
# CHECK-NEXT:     activation_le_scale: 0
# CHECK-NEXT:     activation_le_rshift: 0
# CHECK-NEXT:     right_shift_width: {{.*}}
# CHECK-NEXT:     bn_right_shift_width: 0
# CHECK-NEXT:     scale_right_shift_width: 0
# CHECK-NEXT:     use_winograd: false
# CHECK-NEXT:   }
# CHECK-NEXT: }
# CHECK:      inst {
# CHECK-NEXT:   name: "pool1_1"
# CHECK-NEXT:   type: "bmnet_pooling_fixed_forward_bmkernel"
# CHECK-NEXT:   pooling {
# CHECK-NEXT:     ifmap_gaddr: {{.*}}
# CHECK-NEXT:     ofmap_gaddr: {{.*}}
# CHECK-NEXT:     index_gaddr: 1099511627775
# CHECK-NEXT:     o_findex_gaddr: 1099511627775
# CHECK-NEXT:     n: 1
# CHECK-NEXT:     c: 20
# CHECK-NEXT:     h: 24
# CHECK-NEXT:     w: 24
# CHECK-NEXT:     kh: 2
# CHECK-NEXT:     kw: 2
# CHECK-NEXT:     pad_top: 0
# CHECK-NEXT:     pad_bot: 1
# CHECK-NEXT:     pad_left: 0
# CHECK-NEXT:     pad_right: 1
# CHECK-NEXT:     stride_h: 2
# CHECK-NEXT:     stride_w: 2
# CHECK-NEXT:     is_avg_pooling: 0
# CHECK-NEXT:     avg_const: 0
# CHECK-NEXT:     do_relu: 0
# CHECK-NEXT:     right_shift_width: {{.*}}
# CHECK-NEXT:     threshold_x_quantized: {{.*}}
# CHECK-NEXT:     ceil_mode: false
# CHECK-NEXT:   }
# CHECK-NEXT: }
# CHECK:      inst {
# CHECK-NEXT:   name: "conv2_1"
# CHECK-NEXT:   type: "bmnet_conv_parallel_fixed_forward_bmkernel"
# CHECK-NEXT:   conv_p {
# CHECK-NEXT:     ga_ifmap: {{.*}}
# CHECK-NEXT:     ga_ofmap: {{.*}}
# CHECK-NEXT:     ga_weight: {{.*}}
# CHECK-NEXT:     ga_bias: {{.*}}
# CHECK-NEXT:     ga_bn_mean: 1099511627775
# CHECK-NEXT:     ga_bn_variance: 1099511627775
# CHECK-NEXT:     ga_scale: 1099511627775
# CHECK-NEXT:     ga_scale_bias: 1099511627775
# CHECK-NEXT:     input_n: 1
# CHECK-NEXT:     input_c: 20
# CHECK-NEXT:     input_h: 12
# CHECK-NEXT:     input_w: 12
# CHECK-NEXT:     groups: 1
# CHECK-NEXT:     output_c: 50
# CHECK-NEXT:     kh: 5
# CHECK-NEXT:     kw: 5
# CHECK-NEXT:     dilation_h: 1
# CHECK-NEXT:     dilation_w: 1
# CHECK-NEXT:     pad_h: 0
# CHECK-NEXT:     pad_w: 0
# CHECK-NEXT:     stride_h: 1
# CHECK-NEXT:     stride_w: 1
# CHECK-NEXT:     result_add: 0
# CHECK-NEXT:     do_bias: 1
# CHECK-NEXT:     do_bn: 0
# CHECK-NEXT:     do_scale: 0
# CHECK-NEXT:     do_scale_bias: 0
# CHECK-NEXT:     do_activation: 0
# CHECK-NEXT:     bn_scale: 0
# CHECK-NEXT:     bn_eps: 0
# CHECK-NEXT:     activation_method: 0
# CHECK-NEXT:     activation_arg: 0
# CHECK-NEXT:     activation_ga_slope: 0
# CHECK-NEXT:     activation_channel_shared: false
# CHECK-NEXT:     activation_gt_scale: 0
# CHECK-NEXT:     activation_gt_rshift: 0
# CHECK-NEXT:     activation_le_scale: 0
# CHECK-NEXT:     activation_le_rshift: 0
# CHECK-NEXT:     right_shift_width: {{.*}}
# CHECK-NEXT:     bn_right_shift_width: 0
# CHECK-NEXT:     scale_right_shift_width: 0
# CHECK-NEXT:     use_winograd: false
# CHECK-NEXT:   }
# CHECK-NEXT: }
# CHECK:      inst {
# CHECK-NEXT:   name: "pool2_1"
# CHECK-NEXT:   type: "bmnet_pooling_fixed_forward_bmkernel"
# CHECK-NEXT:   pooling {
# CHECK-NEXT:     ifmap_gaddr: {{.*}}
# CHECK-NEXT:     ofmap_gaddr: {{.*}}
# CHECK-NEXT:     index_gaddr: 1099511627775
# CHECK-NEXT:     o_findex_gaddr: 1099511627775
# CHECK-NEXT:     n: 1
# CHECK-NEXT:     c: 50
# CHECK-NEXT:     h: 8
# CHECK-NEXT:     w: 8
# CHECK-NEXT:     kh: 2
# CHECK-NEXT:     kw: 2
# CHECK-NEXT:     pad_top: 0
# CHECK-NEXT:     pad_bot: 1
# CHECK-NEXT:     pad_left: 0
# CHECK-NEXT:     pad_right: 1
# CHECK-NEXT:     stride_h: 2
# CHECK-NEXT:     stride_w: 2
# CHECK-NEXT:     is_avg_pooling: 0
# CHECK-NEXT:     avg_const: 0
# CHECK-NEXT:     do_relu: 0
# CHECK-NEXT:     right_shift_width: {{.*}}
# CHECK-NEXT:     threshold_x_quantized: {{.*}}
# CHECK-NEXT:     ceil_mode: false
# CHECK-NEXT:   }
# CHECK-NEXT: }
# CHECK:      inst {
# CHECK-NEXT:   name: "relu1_1"
# CHECK-NEXT:   type: "bmnet_fc_fixed_forward_bmkernel"
# CHECK-NEXT:   fc {
# CHECK-NEXT:     bottom_data_gaddr: {{.*}}
# CHECK-NEXT:     weight_data_gaddr: {{.*}}
# CHECK-NEXT:     bias_data_gaddr: {{.*}}
# CHECK-NEXT:     top_data_gaddr: {{.*}}
# CHECK-NEXT:     input_row_num: 1
# CHECK-NEXT:     input_col_num: 800
# CHECK-NEXT:     weight_col_num: 500
# CHECK-NEXT:     have_bias: 1
# CHECK-NEXT:     do_activation: 1
# CHECK-NEXT:     activation_method: 0
# CHECK-NEXT:     activation_ga_slope: 1099511627775
# CHECK-NEXT:     activation_channel_shared: 0
# CHECK-NEXT:     activation_gt_scale: 0
# CHECK-NEXT:     activation_gt_rshift: 0
# CHECK-NEXT:     activation_le_scale: 0
# CHECK-NEXT:     activation_le_rshift: 0
# CHECK-NEXT:     weight_transpose: true
# CHECK-NEXT:     left_shift_width: 0
# CHECK-NEXT:     right_shift_width: {{.*}}
# CHECK-NEXT:   }
# CHECK-NEXT: }
# CHECK:      inst {
# CHECK-NEXT:   name: "ip2_1"
# CHECK-NEXT:   type: "bmnet_fc_fixed_forward_bmkernel"
# CHECK-NEXT:   fc {
# CHECK-NEXT:     bottom_data_gaddr: {{.*}}
# CHECK-NEXT:     weight_data_gaddr: {{.*}}
# CHECK-NEXT:     bias_data_gaddr: {{.*}}
# CHECK-NEXT:     top_data_gaddr: {{.*}}
# CHECK-NEXT:     input_row_num: 1
# CHECK-NEXT:     input_col_num: 500
# CHECK-NEXT:     weight_col_num: 10
# CHECK-NEXT:     have_bias: 1
# CHECK-NEXT:     do_activation: 0
# CHECK-NEXT:     activation_method: 0
# CHECK-NEXT:     activation_ga_slope: 1099511627775
# CHECK-NEXT:     activation_channel_shared: 0
# CHECK-NEXT:     activation_gt_scale: 0
# CHECK-NEXT:     activation_gt_rshift: 0
# CHECK-NEXT:     activation_le_scale: 0
# CHECK-NEXT:     activation_le_rshift: 0
# CHECK-NEXT:     weight_transpose: true
# CHECK-NEXT:     left_shift_width: 0
# CHECK-NEXT:     right_shift_width: {{.*}}
# CHECK-NEXT:   }
# CHECK-NEXT: }

ir_version: 3
producer_name: "onnx-caffe2"
producer_version: ""
domain: ""
model_version: 0
doc_string: ""
graph {
  name: "LeNet"
  doc_string: ""
  node { input: "data_0" input: "conv1_w_0" input: "conv1_b_0" output: "conv1_1" name: "conv1_1" op_type: "Conv" attribute { name: "pads" ints: 0 ints: 0 ints: 0 ints: 0 type: INTS } attribute { name: "strides" ints: 1 ints: 1 type: INTS } attribute { name: "kernel_shape" ints: 5 ints: 5 type: INTS } }
  node { input: "conv1_1" output: "pool1_1" name: "pool1_1" op_type: "MaxPool" attribute { name: "pads" ints: 0 ints: 0 ints: 1 ints: 1 type: INTS } attribute { name: "kernel_shape" ints: 2 ints: 2 type: INTS } attribute { name: "strides" ints: 2 ints: 2 type: INTS } }
  node { input: "pool1_1" input: "conv2_w_0" input: "conv2_b_0" output: "conv2_1" name: "conv2_1" op_type: "Conv" attribute { name: "pads" ints: 0 ints: 0 ints: 0 ints: 0 type: INTS } attribute { name: "strides" ints: 1 ints: 1 type: INTS } attribute { name: "kernel_shape" ints: 5 ints: 5 type: INTS } }
  node { input: "conv2_1" output: "pool2_1" name: "pool2_1" op_type: "MaxPool" attribute { name: "pads" ints: 0 ints: 0 ints: 1 ints: 1 type: INTS } attribute { name: "kernel_shape" ints: 2 ints: 2 type: INTS } attribute { name: "strides" ints: 2 ints: 2 type: INTS } }
  node { input: "pool2_1" input: "OC2_DUMMY_1" output: "OC2_DUMMY_0" name: "OC2_DUMMY_0" op_type: "Reshape" }
  node { input: "OC2_DUMMY_0" input: "ip1_w_0" input: "ip1_b_0" output: "ip1_1" name: "ip1_1" op_type: "Gemm" attribute { name: "transB" i: 1 type: INT } attribute { name: "broadcast" i: 1 type: INT } }
  node { input: "ip1_1" output: "relu1_1" name: "relu1_1" op_type: "Relu" }
  node { input: "relu1_1" input: "ip2_w_0" input: "ip2_b_0" output: "ip2_1" name: "ip2_1" op_type: "Gemm" attribute { name: "transB" i: 1 type: INT } attribute { name: "broadcast" i: 1 type: INT } }
  node { input: "ip2_1" output: "prob_1" name: "prob_1" op_type: "Softmax" }
  input { name: "data_0" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 1 } dim { dim_value: 1 } dim { dim_value: 28 } dim { dim_value: 28 } } } } }
  input { name: "conv1_w_0" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 20 } dim { dim_value: 1 } dim { dim_value: 5 } dim { dim_value: 5 } } } } }
  input { name: "conv1_b_0" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 20 } } } } }
  input { name: "conv2_w_0" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 50 } dim { dim_value: 20 } dim { dim_value: 5 } dim { dim_value: 5 } } } } }
  input { name: "conv2_b_0" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 50 } } } } }
  input { name: "ip1_w_0" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 500 } dim { dim_value: 800 } } } } }
  input { name: "ip1_b_0" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 500 } } } } }
  input { name: "ip2_w_0" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 10 } dim { dim_value: 500 } } } } }
  input { name: "ip2_b_0" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 10 } } } } }
  input { name: "OC2_DUMMY_1" type { tensor_type { elem_type: INT64 shape { dim { dim_value: 2 } } } } }
  output { name: "prob_1" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 1 } dim { dim_value: 10 } } } } }
  value_info { name: "conv1_1" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 1 } dim { dim_value: 20 } dim { dim_value: 24 } dim { dim_value: 24 } } } } }
  value_info { name: "pool1_1" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 1 } dim { dim_value: 20 } dim { dim_value: 12 } dim { dim_value: 12 } } } } }
  value_info { name: "conv2_1" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 1 } dim { dim_value: 50 } dim { dim_value: 8 } dim { dim_value: 8 } } } } }
  value_info { name: "pool2_1" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 1 } dim { dim_value: 50 } dim { dim_value: 4 } dim { dim_value: 4 } } } } }
  value_info { name: "OC2_DUMMY_0" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 1 } dim { dim_value: 800 } } } } }
  value_info { name: "ip1_1" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 1 } dim { dim_value: 500 } } } } }
  value_info { name: "relu1_1" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 1 } dim { dim_value: 500 } } } } }
  value_info { name: "ip2_1" type { tensor_type { elem_type: FLOAT shape { dim { dim_value: 1 } dim { dim_value: 10 } } } } }
  initializer { 
dims: 2
data_type: INT64
name: "OC2_DUMMY_1"
raw_data: "\001\000\000\000\000\000\000\000 \003\000\000\000\000\000\000"
 }
}
opset_import { domain: "" version: 6 }
metadata_props { key: "bm1880_ctable" value: "layer {\n  name: \"data_0\"\n  blob_param {\n    name: \"data_0\"\n    threshold_y: 0.99658036\n  }\n}\nlayer {\n  name: \"conv1_1\"\n  blob_param {\n    name: \"conv1_1\"\n    threshold_y: 1.835129\n  }\n}\nlayer {\n  name: \"pool1_1\"\n  blob_param {\n    name: \"pool1_1\"\n    threshold_y: 1.835129\n  }\n}\nlayer {\n  name: \"conv2_1\"\n  blob_param {\n    name: \"conv2_1\"\n    threshold_y: 5.0528378\n  }\n}\nlayer {\n  name: \"pool2_1\"\n  blob_param {\n    name: \"pool2_1\"\n    threshold_y: 4.4557886\n  }\n}\nlayer {\n  name: \"OC2_DUMMY_0\"\n  blob_param {\n    name: \"OC2_DUMMY_0\"\n    threshold_y: 4.4557886\n  }\n  blob_param {\n    name: \"OC2_DUMMY_2\"\n    threshold_y: 0\n  }\n}\nlayer {\n  name: \"ip1_1\"\n  blob_param {\n    name: \"ip1_1\"\n    threshold_y: 4.9610548\n  }\n}\nlayer {\n  name: \"relu1_1\"\n  blob_param {\n    name: \"relu1_1\"\n    threshold_y: 4.9610548\n  }\n}\nlayer {\n  name: \"ip2_1\"\n  blob_param {\n    name: \"ip2_1\"\n    threshold_y: 13.257649\n  }\n}\nlayer {\n  name: \"prob_1\"\n  blob_param {\n    name: \"prob_1\"\n    threshold_y: 1.0004244\n  }\n}\n" }
metadata_props { key: "data_scale" value: "0.00390625" }
metadata_props { key: "initializers" value: "conv1_w_0,conv1_b_0,conv2_w_0,conv2_b_0,ip1_w_0,ip1_b_0,ip2_w_0,ip2_b_0" }
