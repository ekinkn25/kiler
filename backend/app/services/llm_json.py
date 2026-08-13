"""LLM yanıtları -> JSON. Görme ve sohbet modülleri ortak
Ayrı modülde: chat paketi vision'a bağımlı olmasın"""

import json 
import logging
import re
from app.core.exceptions import AppError, ExternalServiceError
logger = logging.getLogger(__name__)

class LlmInvalidResponse(ExternalServiceError):
    code = "llm_invalid_response"
    message = "model geçerli bir yanıt üretemedi"

_FENCE = re.compile(r"```(?:json)?\s*(.*?)\s*```", re.DOTALL)
_THINK = re.compile(r"<think>.*?</think>", re.DOTALL)

def extract_json(text: str, *, error_cls: type[AppError] = LlmInvalidResponse) -> dict:
    """model yanıtı -> json
    üç aşamalı deneme
    error_cls: çağıran modülün kendi gata sınıfını geçirmesini sağlar böylece çağıran kod tek bir hata hiyerarşisiyle uğraşır"""
    if not text or not text.strip():
        raise error_cls("model boş yanıt döndü.")
    text = _THINK.sub("", text)
    if "</think>" in text:
        text = text.rsplit("</think>", 1)[-1]
    text = text.strip()
    if not text: 
        raise error_cls("model yalnızca akıl yürütme metni döndürdü")

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    if m := _FENCE.search(text):
        try: 
            return json.loads(m.group(1))
        except json.JSONDecodeError:
            pass

    for acilis, kapanis in (("{", "}"), ("[", "]")):
        bas, son = text.find(acilis), text.rfind(kapanis)
        if bas != -1 and son > bas:
            try:
                cozulen = json.loads(text[bas:son + 1])
                return cozulen if isinstance(cozulen, dict) else {"items": cozulen}
            except json.JSONDecodeError:
                continue

    logger.warning(
        "JSON ayristirilamadi (%d karakter). Ham yanit: %s", len(text), text[:1500]
    )
    raise error_cls("Model gecerli JSON dondurmedi.")