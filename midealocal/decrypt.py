from Crypto.Cipher import AES
import binascii
import hashlib
import sys

def decrypt_file(input_file, key):
    # Generate MD5 hash and take first 16 chars
    key_bytes = hashlib.md5(key.encode()).hexdigest()[:16].encode()

    # Print the MD5 hash used as key
    print(f"Using key: {hashlib.md5(key.encode()).hexdigest()[:16]}")
    
    # Read encrypted data
    with open(input_file, 'r') as f:
        hex_str = f.read().strip()
        # Convert hex string to bytes
        encrypted_data = bytes([int(hex_str[i:i+2], 16) for i in range(0, len(hex_str), 2)])
    
    # Create cipher object and decrypt the data
    cipher = AES.new(key_bytes, AES.MODE_ECB)
    
    # Add PKCS5 padding if needed
    block_size = 16
    pad_length = block_size - (len(encrypted_data) % block_size)
    if pad_length < block_size:
        encrypted_data += bytes([pad_length] * pad_length)
        
    # Decrypt data
    decrypted_data = cipher.decrypt(encrypted_data)
    
    # Remove padding
    padding_length = decrypted_data[-1]
    decrypted_data = decrypted_data[:-padding_length]
    
    # Convert to string
    decrypted_text = decrypted_data.decode('utf-8')
    
    # Write decrypted data
    output_file = input_file + '.decrypted'
    with open(output_file, 'w') as f:
        f.write(decrypted_text)
    
    print(f"Decrypted file saved as: {output_file}")

# Decrypt the file
app_key = "09c4d09f0da1513bb62dc7b6b0af9c11"  # IoLife app key

if len(sys.argv) < 2:
    print("Usage: python decrypt.py <input_file>")
    sys.exit(1)

input_file = sys.argv[1]
decrypt_file(input_file, app_key)
