import os
import json
import torch
from torch.utils.data import Dataset, DataLoader
from transformers import AutoModelForCausalLM, AutoTokenizer, AdamW

class SocialSyncDataset(Dataset):
    def __init__(self, data_path, tokenizer, max_length=128):
        self.tokenizer = tokenizer
        self.max_length = max_length
        self.examples = []
        
        with open(data_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            
        for item in data:
            # Format the conversation turn
            text = f"User: {item['original_message']}\nSocial Coach: {item['improved_message']}{tokenizer.eos_token}"
            self.examples.append(text)
            
    def __len__(self):
        return len(self.examples)
        
    def __getitem__(self, idx):
        text = self.examples[idx]
        inputs = self.tokenizer(
            text,
            truncation=True,
            max_length=self.max_length,
            padding="max_length",
            return_tensors="pt"
        )
        # Squeeze to remove batch dimension from single item
        input_ids = inputs["input_ids"].squeeze(0)
        attention_mask = inputs["attention_mask"].squeeze(0)
        
        # In causal LM, labels are identical to input_ids, with padding ignored (-100)
        labels = input_ids.clone()
        labels[labels == self.tokenizer.pad_token_id] = -100
        
        return {
            "input_ids": input_ids,
            "attention_mask": attention_mask,
            "labels": labels
        }

def train_model():
    print("[ML Training] Starting DialoGPT fine-tuning pipeline...")
    
    # Path to dataset
    dataset_path = os.path.join(os.path.dirname(__file__), "..", "socialsync_dataset.json")
    if not os.path.exists(dataset_path):
        print("[ML Training] Generating dataset first...")
        from generate_custom_dataset import generate_dataset
        generate_dataset()
        
    # Load tokenizer and model
    model_name = "microsoft/DialoGPT-small"
    print(f"[ML Training] Loading model and tokenizer: {model_name}...")
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    tokenizer.pad_token = tokenizer.eos_token
    
    model = AutoModelForCausalLM.from_pretrained(model_name)
    
    # Prepare DataLoader
    dataset = SocialSyncDataset(dataset_path, tokenizer)
    dataloader = DataLoader(dataset, batch_size=4, shuffle=True)
    
    # Optimizer
    optimizer = AdamW(model.parameters(), lr=5e-5)
    
    # Training Loop (3 epochs is fast and sufficient for fine-tuning on 100 samples)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"[ML Training] Training on device: {device}")
    model.to(device)
    
    model.train()
    epochs = 3
    for epoch in range(epochs):
        total_loss = 0
        for batch in dataloader:
            optimizer.zero_grad()
            input_ids = batch["input_ids"].to(device)
            attention_mask = batch["attention_mask"].to(device)
            labels = batch["labels"].to(device)
            
            outputs = model(
                input_ids=input_ids,
                attention_mask=attention_mask,
                labels=labels
            )
            loss = outputs.loss
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
            
        avg_loss = total_loss / len(dataloader)
        print(f"[ML Training] Epoch {epoch + 1}/{epochs} - Average Loss: {avg_loss:.4f}")
        
    # Save the fine-tuned checkpoint
    output_dir = os.path.join(os.path.dirname(__file__), "..", "models", "dialogpt_finetuned")
    os.makedirs(output_dir, exist_ok=True)
    model.save_pretrained(output_dir)
    tokenizer.save_pretrained(output_dir)
    print(f"[ML Training] Fine-tuned model saved to {output_dir}")

if __name__ == "__main__":
    train_model()
