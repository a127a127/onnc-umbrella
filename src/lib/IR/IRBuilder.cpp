//===- IRBuilder.cpp ------------------------------------------------------===//
//
//                             The ONNC Project
//
// See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include <onnc/IR/Compute/Tensor.h>
#include <onnc/IR/IRBuilder.h>
#include <onnx/onnx.pb.h>

using namespace onnc;

//===----------------------------------------------------------------------===//
// IRBuilder
//===----------------------------------------------------------------------===//
IRBuilder::IRBuilder(Module& pModule)
  : m_InsertionPoint() {
  m_InsertionPoint.setModule(pModule);
}

IRBuilder::IRBuilder(Module& pModule, const ::onnx::ModelProto& pProto)
  : m_InsertionPoint() {
  m_InsertionPoint.setModule(pModule);
  update(pProto);
}

void IRBuilder::setInsertionPoint(const InsertionPoint& pISP)
{
  m_InsertionPoint = pISP;
}

void IRBuilder::update(const ::onnx::ModelProto& pProto)
{
  getModule().delegate(::onnx::ImportModelProto(pProto));

  if (pProto.has_ir_version())
    getModule().getOnnxInfo().setIRVersion(pProto.ir_version());

  if (pProto.has_producer_name())
    getModule().getOnnxInfo().setProducerName(pProto.producer_name());

  if (pProto.has_producer_version())
    getModule().getOnnxInfo().setProducerVersion(pProto.producer_version());

  if (pProto.has_domain())
    getModule().getOnnxInfo().setDomain(pProto.domain());

  if (pProto.has_model_version())
    getModule().getOnnxInfo().setModelVersion(pProto.model_version());

  if (pProto.has_doc_string())
    getModule().getOnnxInfo().setDocString(pProto.doc_string());

  for (int i = 0; i < pProto.opset_import_size(); i++) {
    auto &opset = pProto.opset_import(i);
    getModule().getSetId().insert({ opset.domain(), opset.version() });
  }

  for (int i = 0; i < pProto.metadata_props_size(); i++) {
    auto &strStrEntry = pProto.metadata_props(i);
    getModule().getMetaData().insert({ strStrEntry.key(), strStrEntry.value() });
  }

  getInsertionPoint().setTensorGraph(*getModule().getGraphIR().get());
}

void IRBuilder::setComputeGraph(ComputeGraph* pCG)
{
  getInsertionPoint().setComputeGraph(pCG);
}

/// create a tensor graph
::onnx::Graph* IRBuilder::CreateTensorGraph()
{
  ::onnx::Graph* result = new ::onnx::Graph();
  getInsertionPoint().setTensorGraph(*result);
  getModule().delegate(*getTensorGraph());
  return getTensorGraph();
}

/// create a tensor graph whose name is @ref pName
::onnx::Graph* IRBuilder::CreateTensorGraph(StringRef pName)
{
  ::onnx::Graph* result = new ::onnx::Graph();
  getInsertionPoint().setTensorGraph(*result);
  getModule().delegate(*getTensorGraph());
  getTensorGraph()->setName(pName);
  return getTensorGraph();
}

::onnx::Value* IRBuilder::AddInput(const std::string& pName,
                                   const std::vector<::onnx::Dimension>& pSizes,
                                   onnc::Value::Type pKind)
{
  if (!hasTensorGraph())
    return nullptr;

  bool exist = false;
  InsertionPoint::CreatedValues::entry_type* entry =
      getInsertionPoint().getCreatedValues().insert(pName, exist);

  /// the created input should be unique
  if (exist)
    return nullptr;

  ::onnx::Value *result = getTensorGraph()->addInput();
  result->setUniqueName(pName)
        ->setSizes(pSizes)
        ->setElemType((onnx::TensorProto_DataType)pKind);

  entry->setValue(result);
  return result;
}

::onnx::Node*
IRBuilder::AddNode(const std::string& pName, const StringList& pInputNames)
{
  if (!hasTensorGraph())
    return nullptr;

  ::onnx::Node *node = getTensorGraph()->create(::onnx::Symbol(pName));
  // make sure every input name exists
  for (auto & input : pInputNames) {
    if (getInsertionPoint().getCreatedValues().end() ==
        getInsertionPoint().getCreatedValues().find(input))
      return nullptr;
  }

  // complete the node's inputs
  for (auto & input : pInputNames) {
    node->addInput(getInsertionPoint().getCreatedValues().find(input)->value());
  }

  getTensorGraph()->appendNode(node);
  getInsertionPoint().setTensorNode(*node);
  return node;
}

::onnx::Node* IRBuilder::CloneNode(::onnx::Node& pNode, const std::string& pName)
{
  ::onnx::Graph* graph = pNode.owningGraph();

  // kind and graph
  ::onnx::Node *node = graph->create(pNode.kind());

  // name
  if (!pName.empty())
    node->setName(pName);

  // copy doc_strings
  std::string doc_string(pNode.docString());
  node->setDocString(doc_string);

  // attributes
  node->copyAttributes(pNode);

  getInsertionPoint().setTensorNode(*node);
  return node;
}

onnc::InitializerProxy
IRBuilder::AddInitializer(const std::string& pName,
                          const std::vector<::onnx::Dimension>& pSizes,
                          onnc::Value::Type pKind)
{
  if (!hasTensorGraph())
    return InitializerProxy();

  // XXX: using local variables because ::onnx::Graph::addInitializer does
  // delegation (through std::move).
  ::onnx::Tensor t;
  t.elem_type() = (::onnx::TensorProto_DataType)pKind;
  t.setName(pName);

  if (pSizes.empty()) { // find from created values
    bool exist = false;
    InsertionPoint::CreatedValues::entry_type* entry =
        getInsertionPoint().getCreatedValues().insert(pName, exist);
    if (exist) {
      t.sizes().reserve(entry->value()->sizes().size());
      for (::onnx::Dimension d : entry->value()->sizes())
        t.sizes().push_back(d.dim);
    }
  }
  else {
    t.sizes().reserve(pSizes.size());
    for (::onnx::Dimension d : pSizes)
      t.sizes().push_back(d.dim);
  }

  getTensorGraph()->addInitializer(t, pName);

  // XXX: using back() because ::onnx::Graph::addInitializer is an appending.
  onnc::InitializerProxy result(getTensorGraph()->initializer_names().back(),
                                getTensorGraph()->initializers().back());
  return result;
}

::onnx::Value*
IRBuilder::AddOutput(const std::string& pName,
                     const std::vector<::onnx::Dimension>& pSizes,
                     onnc::Value::Type pKind)
{
  if (!hasTensorNode())
    return nullptr;

  bool exist = false;
  InsertionPoint::CreatedValues::entry_type* entry =
      getInsertionPoint().getCreatedValues().insert(pName, exist);

  /// the created output value should be unique
  if (exist)
    return nullptr;

  /// XXX: ONNX has already created a default output value. If we are
  /// in the very first adding, then use the created one.
  ::onnx::Value *out = nullptr;
  if (1 < getTensorNode()->outputs().size())
    out = getTensorNode()->addOutput();
  else
    out = getTensorNode()->output();

  out->setUniqueName(pName)
     ->setSizes(pSizes)
     ->setElemType((onnx::TensorProto_DataType)pKind);

  // books the value
  entry->setValue(out);

  return out;
}

bool IRBuilder::FinalizeTensorGraph(const StringList& pOutputs)
{
  for (auto & output : pOutputs) {
    if (getInsertionPoint().getCreatedValues().end() ==
        getInsertionPoint().getCreatedValues().find(output))
      return false;
  }

  for (auto & output : pOutputs) {
    // register graph output
    getTensorGraph()->registerOutput(
        getInsertionPoint().getCreatedValues().find(output)->value());
  }
  return true;
}

Tensor* IRBuilder::CreateComputeTensor(const ::onnx::Value& pValue,
                                       const ::onnx::Tensor* pTensor)
{
  const std::string &name = pValue.uniqueName();
  ComputeGraph& cg = *getComputeGraph();
  Tensor* onncTensor;
  switch (pValue.elemType()) {
  case Value::kInt8: {
    auto t = cg.addValue<Int8Tensor>(name);
    // Copy initializing data from tensor.
    if (pTensor) {
      if (pTensor->is_raw_data()) {
        int32_t* d = (int32_t*)pTensor->raw().c_str();
        for (size_t i = 0; i < pTensor->raw().size() / sizeof(int32_t); ++i)
          t->getValues().push_back(d[i]);
      } else {
        for (int i : pTensor->int32s())
          t->getValues().push_back(i);
      }
    }
    onncTensor = t;
    break;
  }
  case Value::kInt16: {
    auto t = cg.addValue<Int16Tensor>(name);
    // Copy initializing data from tensor.
    if (pTensor)
      for (int i : pTensor->int32s())
        t->getValues().push_back(i);
    onncTensor = t;
    break;
  }
  case Value::kInt32: {
    auto t = cg.addValue<Int32Tensor>(name);
    // Copy initializing data from tensor.
    if (pTensor)
      t->getValues() = pTensor->int32s();
    onncTensor = t;
    break;
  }
  case Value::kInt64: {
    auto t = cg.addValue<Int64Tensor>(name);
    // Copy initializing data from tensor.
    if (pTensor)
      t->getValues() = pTensor->int64s();
    onncTensor = t;
    break;
  }
  case Value::kUint8:   onncTensor = cg.addValue<Uint8Tensor>(name); break;
  case Value::kUint16:  onncTensor = cg.addValue<Uint16Tensor>(name); break;
  case Value::kUint32:  onncTensor = cg.addValue<Uint32Tensor>(name); break;
  case Value::kUint64:  onncTensor = cg.addValue<Uint64Tensor>(name); break;
  case Value::kFloat:   onncTensor = cg.addValue<FloatTensor>(name); break;
  case Value::kFloat16: onncTensor = cg.addValue<Float16Tensor>(name); break;
  case Value::kString:  onncTensor = cg.addValue<StringTensor>(name); break;
  case Value::kBoolean: onncTensor = cg.addValue<BooleanTensor>(name); break;
  case Value::kDouble:  onncTensor = cg.addValue<DoubleTensor>(name); break;
  default:
    errs() << "createTensor error: unknow elemtype = "
           << pValue.elemType() << "\n";
    return nullptr;
  }

  std::vector<int64_t> sizes(pValue.sizes().size());
  for (int i = 0; i < pValue.sizes().size(); ++i)
    sizes[i] = pValue.sizes()[i].dim;
  onncTensor->setDimensions(sizes);

  return onncTensor;
}