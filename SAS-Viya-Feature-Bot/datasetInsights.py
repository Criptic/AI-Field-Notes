import pandas as pd

df = pd.read_csv('../Datasets/SAS-Whats-New.csv')
average_length = (df['Short Update'].astype(str) + df['Long Update'].astype(str)).str.len().mean()
max_length = (df['Short Update'].astype(str) + df['Long Update'].astype(str)).str.len().max()
row_with_max_length = df.loc[(df['Short Update'].astype(str) + df['Long Update'].astype(str)).str.len().idxmax()]
print(f'Average length: {average_length}')
print(f'Max length: {max_length}')
print(f'Row with max length:\n{row_with_max_length}')