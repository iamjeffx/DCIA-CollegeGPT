from typing import List, Union, Dict, Any

from jsonformer.logits_processors import (
    NumberStoppingCriteria,
    StringStoppingCriteria,
)

def generate_number(self, temperature: Union[float, None] = None, iterations=0):
        prompt = self.get_prompt()
        self.debug("[generate_number]", prompt, is_prompt=True)
        input_tokens = self.tokenizer.encode(prompt, return_tensors="pt").to(
            self.model.device
        )
        response = self.model.generate(
            inputs=input_tokens,
            max_new_tokens=self.max_number_tokens,
            num_return_sequences=1,
            logits_processor=[self.number_logit_processor],
            stopping_criteria=[
                NumberStoppingCriteria(self.tokenizer, len(input_tokens[0]))
            ],
            temperature=temperature or self.temperature,
            pad_token_id=self.tokenizer.eos_token_id,
        )
        response = self.tokenizer.decode(response[0], skip_special_tokens=True)

        response = response[len(prompt) :]
        response = response.strip().rstrip(".")
        self.debug("[generate_number]", response)
        try:
            return float(response)
        except ValueError:
            if iterations > 3:
                raise ValueError("Failed to generate a valid number")

            return self.generate_number(temperature=self.temperature * 1.3)
        
def generate_string(self) -> str:
        prompt = f'{self.get_prompt()}"'
        self.debug("[generate_string]", prompt, is_prompt=True)
        input_tokens = self.tokenizer.encode(prompt, return_tensors="pt").to(
            self.model.device
        )
        response = self.model.generate(
            inputs=input_tokens,
            max_new_tokens=self.max_string_token_length,
            num_return_sequences=1,
            temperature=self.temperature,
            stopping_criteria=[
                StringStoppingCriteria(self.tokenizer, len(input_tokens[0]))
            ],
            pad_token_id=self.tokenizer.eos_token_id,
        )

        # Some models output the prompt as part of the response
        # This removes the prompt from the response if it is present
        if (
            len(response[0]) >= len(input_tokens[0])
            and (response[0][: len(input_tokens[0])] == input_tokens).all()
        ):
            response = response[0][len(input_tokens[0]) :]
        if response.shape[0] == 1:
            response = response[0]

        response = self.tokenizer.decode(response, skip_special_tokens=True)

        self.debug("[generate_string]", f"|{response}|")

        if response.count('"') < 1:
            return response

        return response.split('"')[0].strip()