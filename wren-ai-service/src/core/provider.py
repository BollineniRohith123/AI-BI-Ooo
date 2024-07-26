from abc import ABCMeta, abstractmethod

from haystack.document_stores.types import DocumentStore


class LLMProvider(metaclass=ABCMeta):
    @abstractmethod
    def get_generator(self, *args, **kwargs):
        ...

    def get_model(self):
        return self._generation_model


class EmbedderProvider(metaclass=ABCMeta):
    @abstractmethod
    def get_text_embedder(self, *args, **kwargs):
        ...

    @abstractmethod
    def get_document_embedder(self, *args, **kwargs):
        ...

    def get_model(self):
        return self._embedding_model


class DocumentStoreProvider(metaclass=ABCMeta):
    @abstractmethod
    def get_store(self, *args, **kwargs) -> DocumentStore:
        ...

    @abstractmethod
    def get_retriever(self, *args, **kwargs):
        ...
