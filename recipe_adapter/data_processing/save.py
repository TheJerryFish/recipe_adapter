"""
PyTorch -> onnx -> coreml conversion

Credits: 

Bhushan Sonawane https://github.com/bhushan23 Apple, Inc.

https://github.com/onnx/onnx-coreml/issues/478

"""
import os
import timeit
import numpy as np
import torch
import coremltools as ct
from transformers.modeling_distilbert import DistilBertForQuestionAnswering

SEQUENCE_LENGTH = 384
MODEL_NAME = "distilbert-base-uncased"


model = DistilBertForQuestionAnswering.from_pretrained(MODEL_NAME, torchscript=True)
# torch.save(model, "./distilbert.pt")
model.eval()

example_input = torch.rand(1, 3, 224, 224)
traced_model = torch.jit.trace(model, example_input)

model_from_trace = ct.convert(
    traced_model,
    inputs=[ct.TensorType(shape=example_input.shape)],
)
model_from_trace.save("newmodel_from_trace.mlpackage")
