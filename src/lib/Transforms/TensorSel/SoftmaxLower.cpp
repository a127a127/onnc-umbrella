//===- SoftmaxLower.cpp ---------------------------------------------------===//
//
//                             The ONNC Project
//
// See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include <onnc/Transforms/TensorSel/Lower.h>
#include <onnc/Transforms/TensorSel/Standards/SoftmaxLower.h>
#include <onnc/IR/Compute/Softmax.h>

using namespace onnc;

//===----------------------------------------------------------------------===//
// SoftmaxLower
//===----------------------------------------------------------------------===//
SoftmaxLower::SoftmaxLower()
{
}

SoftmaxLower::~SoftmaxLower()
{
}

int SoftmaxLower::isMe(const ::onnx::Node& pNode) const
{
  if (pNode.kind() == ::onnx::Symbol("Softmax"))
    return kStdLower;
  return kNotMe;
}

ComputeOperator*
SoftmaxLower::activate(ComputeGraph& pGraph, ::onnx::Node& pNode) const
{
  // check input/output name
  if (1 != pNode.inputs().size())
    return nullptr;

  for (::onnx::Value* xv : pNode.inputs()) {
    if (!xv->has_unique_name())
      return nullptr;
  }

  if (1 != pNode.outputs().size())
    return nullptr;

  for (::onnx::Value* xv : pNode.outputs()) {
    if (!xv->has_unique_name())
      return nullptr;
  }

  // create operators
  onnc::Softmax* op = pGraph.addOperator<onnc::Softmax>();

  // set optional attributes
  if (pNode.hasAttribute(::onnx::Symbol("axis")))
    op->setAxis(pNode.i(::onnx::Symbol("axis")));

  // set input/output
  for (::onnx::Value* xv : pNode.inputs())
    op->addInput(*pGraph.getValue<onnc::Tensor>(xv->uniqueName()));

  for (::onnx::Value* xv : pNode.outputs())
    op->addOutput(*pGraph.getValue<onnc::Tensor>(xv->uniqueName()));

  return op;
}