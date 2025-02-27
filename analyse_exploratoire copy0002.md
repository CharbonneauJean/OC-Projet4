---
jupyter:
  jupytext:
    text_representation:
      extension: .md
      format_name: markdown
      format_version: '1.3'
      jupytext_version: 1.16.7
  kernelspec:
    display_name: oc-p4
    language: python
    name: python3
---

# Projet 4 - Segmentation des clients d'un site e-commerce

## Analyse exploratoire et création d'un dataset clean

Le but de ce notebook est d'analyser le jeu de données initial et de le traiter afin de produire un dataset "clean", exporté en csv, qui sera la base du travail de machine learning consécutif.

### Table des matières
1. [Importation et préparation des données](#1-importation-et-préparation-des-données)
2. [Analyse des données manquantes](#2-analyse-des-données-manquantes)
3. [Analyse des variables numériques](#3-analyse-des-variables-numériques)
4. [Analyse des variables catégorielles](#4-analyse-des-variables-catégorielles)
5. [Analyse des corrélations](#5-analyse-des-corrélations)
6. [Feature Engineering](#6-feature-engineering)
6.5. [Analyse RFM préliminaire](#65-analyse-rfm-préliminaire)
7. [Traitement des outliers](#7-traitement-des-outliers)
8. [Préparation du dataset final](#8-préparation-du-dataset-final)
9. [Conclusion et prochaines étapes](#9-conclusion-et-prochaines-étapes)


### Imports et paramètres

```python
import pandas as pd
pd.options.mode.chained_assignment = None  # Désactive l'avertissement SettingWithCopyWarning
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from MLUtils import DataAnalysis, DataEngineering

import warnings
warnings.filterwarnings("ignore")

# Pour une meilleure lisibilité des graphiques
plt.style.use('ggplot')  # Utilisation d'un style valide de matplotlib
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 14

# Configuration de seaborn pour une meilleure esthétique
sns.set_theme(style="whitegrid")
```

## 1. Importation et préparation des données

```python
# Importation du jeu de données
df = pd.read_csv('data/customer_segments3_202409201627.csv')
print(f"Le jeu initial de données contient {df.shape[0]} observations réparties en {df.shape[1]} colonnes/variables.")
df.info()
```

```python
df.sample(10)
```

```python
# 6. Feature Engineering

# 1. Calcul du ratio de dépense moyenne par commande
df['avg_spent_per_order'] = df['total_spent'] / df['total_orders']

# 2. Calcul de l'intervalle moyen entre commandes (en jours)
# Pour les clients ayant plus d'une commande, on estime l'intervalle moyen en divisant
# le nombre de jours depuis la dernière commande par (total_orders - 1).
# Pour les clients avec une seule commande, on utilise le nombre de jours depuis la dernière commande
df['avg_days_between_orders'] = df.apply(
    lambda row: row['days_since_last_order'] / (row['total_orders'] - 1) if row['total_orders'] > 1 else np.nan,
    axis=1
)
df['avg_days_between_orders'].fillna(df['days_since_last_order'], inplace=True)

# 3. Calcul d'un score de fidélité combiné
# Un score plus élevé indique un client dépensant beaucoup par commande et passant peu de temps entre ses commandes
df['loyalty_score'] = df['avg_spent_per_order'] / (df['avg_days_between_orders'] + 1)

# 4. Créer une variable binaire pour le type de paiement (1 pour carte de crédit, 0 pour les autres)
df['is_credit_card'] = df['last_payment_type'].apply(lambda x: 1 if x == 'credit_card' else 0)

# 5. Créer une variable pour la récence (plus la valeur est faible, plus le client est récent)
df['recency_score'] = df['days_since_last_order'].rank(pct=True)

# 6. Créer une variable pour la fréquence (inversée par rapport à avg_days_between_orders)
df['frequency_score'] = 1 / (df['avg_days_between_orders'] + 1)

# Affichage des nouvelles variables
print("Aperçu des variables créées par feature engineering:")
display(df[['avg_spent_per_order', 'avg_days_between_orders', 'loyalty_score', 
         'is_credit_card', 'recency_score', 'frequency_score']].head())
```

## 6.5 Analyse RFM préliminaire

```python
# 6.5 Analyse RFM préliminaire
print("### Analyse RFM (Récence, Fréquence, Montant) ###")

# Création des quintiles pour chaque dimension RFM
# Récence (une valeur plus faible = meilleur)
df['R_score'] = pd.qcut(df['days_since_last_order'], q=5, labels=[5, 4, 3, 2, 1])

# Fréquence (via notre variable frequency_score - une valeur plus élevée = meilleur)
df['F_score'] = pd.qcut(df['frequency_score'], q=5, labels=[1, 2, 3, 4, 5])

# Montant (avg_spent_per_order - une valeur plus élevée = meilleur)
df['M_score'] = pd.qcut(df['avg_spent_per_order'], q=5, labels=[1, 2, 3, 4, 5])

# Combinaison des scores RFM
df['RFM_score'] = df['R_score'].astype(str) + df['F_score'].astype(str) + df['M_score'].astype(str)

# Création de segments clients simplifiés
def segment_client(rfm_score):
    r = int(rfm_score[0])
    f = int(rfm_score[1])
    m = int(rfm_score[2])
    
    if r >= 4 and f >= 4 and m >= 4:
        return 'Champions'
    elif r >= 3 and f >= 3 and m >= 3:
        return 'Clients loyaux'
    elif r >= 3 and f >= 1 and m >= 2:
        return 'Clients potentiels'
    elif r <= 2 and f <= 2 and m <= 2:
        return 'Clients à risque'
    elif r == 1 and f == 1 and m == 1:
        return 'Clients perdus'
    else:
        return 'Autres'

df['segment_RFM'] = df['RFM_score'].apply(segment_client)

# Affichage des segments
segment_counts = df['segment_RFM'].value_counts()
print("\nDistribution des segments RFM:")
print(segment_counts)

# Visualisation
plt.figure(figsize=(10, 6))
segment_counts.plot(kind='bar', color=sns.color_palette("viridis", len(segment_counts)))
plt.title('Distribution des segments clients selon analyse RFM')
plt.xlabel('Segment')
plt.ylabel('Nombre de clients')
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
plt.show()

# Analyse des caractéristiques moyennes par segment
segment_profile = df.groupby('segment_RFM').agg({
    'days_since_last_order': 'mean',
    'frequency_score': 'mean',
    'avg_spent_per_order': 'mean',
    'loyalty_score': 'mean'
}).round(2)

print("\nProfil moyen des segments:")
display(segment_profile)
```

## 2. Analyse des données manquantes

```python
missing_percentages = (df.isnull().sum() / len(df)) * 100
print("Pourcentage de valeurs manquantes par colonne:")
display(missing_percentages[missing_percentages > 0])
```

```python
DataAnalysis.show_columns_population(df, 'matrix')
```

```python
df.sample(10)
```

```python
# On supprime la colonne "last_order_date" car elle ne nous sera pas utile, nous avons déjà la colonne "days_since_last_order"
df = df.drop(columns=['last_order_date'])

# On supprime les observations avec des valeurs manquantes
df = df.dropna()
print(f"Après suppression des valeurs manquantes, nous avons {df.shape[0]} observations utilisables.")
```

## 3. Analyse des variables numériques

```python
# Sélection des colonnes numériques
numeric_columns = df.select_dtypes(include=['number']).columns
print("Colonnes numériques :")
print(numeric_columns)

# Statistiques descriptives
df[numeric_columns].describe()
```

```python
import math
import matplotlib.pyplot as plt
import seaborn as sns

# Nombre total de graphiques à tracer
num_plots = len(numeric_columns)
# Définir le nombre de colonnes souhaité, par exemple 3
num_cols = 3
# Calculer le nombre de lignes nécessaires
num_rows = math.ceil(num_plots / num_cols)

fig, axes = plt.subplots(num_rows, num_cols, figsize=(num_cols * 5, num_rows * 4))
axes = axes.flatten()  # Mettre tous les axes dans un tableau 1D

for idx, col in enumerate(numeric_columns):
    sns.histplot(df[col], kde=True, ax=axes[idx])
    axes[idx].set_title(f'Distribution de {col}')
    axes[idx].set_xlabel('')

# Supprimer les axes inutilisés
for ax in axes[num_plots:]:
    fig.delaxes(ax)

plt.tight_layout()
plt.show()

```

```python
def remove_outliers(df, column):
	# Calcul des quartiles et de l'IQR
	Q1 = df[column].quantile(0.25)
	Q3 = df[column].quantile(0.75)
	IQR = Q3 - Q1

	# Définition des bornes
	lower_bound = Q1 - 1.5 * IQR
	upper_bound = Q3 + 1.5 * IQR
	
	# Filtrer le DataFrame
	initial_count = len(df)
	filtered_df = df[(df[column] >= lower_bound) & (df[column] <= upper_bound)]
	removed_count = initial_count - len(filtered_df)
	
	# Affichage des informations
	print(f"Colonne '{column}' : {removed_count} outliers supprimés.")
	print(f"Nouvelles limites : lower_bound = {lower_bound:.2f}, upper_bound = {upper_bound:.2f}")
	
	return filtered_df
```

```python
# 7. Traitement des outliers
# Fonction pour identifier et supprimer les outliers avec la méthode IQR
def remove_outliers(df, column):
    # Calcul des quartiles et de l'IQR
    Q1 = df[column].quantile(0.25)
    Q3 = df[column].quantile(0.75)
    IQR = Q3 - Q1
    
    # Définition des bornes
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR
    
    # Filtrer le DataFrame
    initial_count = len(df)
    filtered_df = df[(df[column] >= lower_bound) & (df[column] <= upper_bound)]
    removed_count = initial_count - len(filtered_df)
    
    # Affichage des informations
    print(f"Colonne '{column}' : {removed_count} outliers supprimés ({removed_count/initial_count*100:.2f}%).")
    print(f"Nouvelles limites : lower_bound = {lower_bound:.2f}, upper_bound = {upper_bound:.2f}")
    
    return filtered_df

# Appliquer la suppression des outliers aux colonnes numériques pertinentes
print("Suppression des outliers sur les variables clés...")
df = remove_outliers(df, 'avg_delivery_time_days')
df = remove_outliers(df, 'last_payment_installments')
df = remove_outliers(df, 'avg_spent_per_order')
df = remove_outliers(df, 'loyalty_score')

print(f"\nAprès suppression des outliers, nous avons {df.shape[0]} observations utilisables.")
```

# Analyse de la colonne 'total_orders'

```python
# Trouver les valeurs différentes et le count pour chacun d'elle pour cette colonne
#df['total_orders'].value_counts()
```

Nous constatons que la plupart des clients ont fait une seule commande. Nous allons donc classer les clients en deux buckets : 
- ceux qui ont fait une seule commande
- ceux qui ont fait plus d'une commande

```python
# Créer une colonne "more_than_one_order" qui sera à 1 si le client a passé plus d'une commande, 0 sinon
df['more_than_one_order'] = df['total_orders'].apply(lambda x: 0 if x == 1 else 1)

# On peut alors drop la colonne "total_orders"
df = df.drop(columns=['total_orders'])

# Enlever 'total_order' de numeric_columns
numeric_columns = numeric_columns.drop('total_orders')

# Ajouter 'more_than_one_order' à numeric_columns
numeric_columns = pd.Index(['more_than_one_order']).append(numeric_columns)
```

# Analyse de la colonne 'avg_delivery_time_days'

On constate sur le graphique de répartition de cette colonne que la courbe est bien lisse pour les valeurs inférieures à 70 jours. Nous allons donc éliminer les valeurs supérieures à 70 jours qui sont des outliers.

```python
# Enlever les lignes avec des valeurs supérieures à 70 pour la colonne 'avg_delivery_time_days'
# df = df[df['avg_delivery_time_days'] <= 70]
```

# Analyse de la colonne 'days_since_last_order'

On constate sur le graphique de répartition de cette colonne que la courbe est bien lisse pour les valeurs inférieures à 650 jours. Nous allons donc éliminer les valeurs supérieures à 650 jours qui sont des outliers.

```python
# Enlever les lignes avec des valeurs supérieures à 70 pour la colonne 'days_since_last_order'
# df = df[df['days_since_last_order'] <= 650]
```

# Analyse de la colonne 'total_spent'

On constate sur le graphique de répartition de cette colonne que la courbe est bien lisse pour les valeurs inférieures à 1000. Nous allons donc éliminer les valeurs supérieures à 1000 qui sont des outliers.

```python
# Enlever les lignes avec des valeurs supérieures à 1000 pour la colonne 'total_spent'
# df = df[df['total_spent'] <= 1000]
```

# Voyons si nos graphes sont plus précis et exploitable maintenant que les outliers ont été enlevés

```python
import math
import matplotlib.pyplot as plt
import seaborn as sns

# Nombre total de graphiques à tracer
num_plots = len(numeric_columns)
# Définir le nombre de colonnes souhaité, par exemple 3
num_cols = 3
# Calculer le nombre de lignes nécessaires
num_rows = math.ceil(num_plots / num_cols)

fig, axes = plt.subplots(num_rows, num_cols, figsize=(num_cols * 5, num_rows * 4))
axes = axes.flatten()  # Mettre tous les axes dans un tableau 1D

for idx, col in enumerate(numeric_columns):
    sns.histplot(df[col], kde=True, ax=axes[idx])
    axes[idx].set_title(f'Distribution de {col}')
    axes[idx].set_xlabel('')

# Supprimer les axes inutilisés
for ax in axes[num_plots:]:
    fig.delaxes(ax)

plt.tight_layout()
plt.show()

```

```python
# show number of lines remaining after removing outliers
print(f"Après suppression des outliers, nous avons {df.shape[0]} observations utilisables.")
```

```python
df.sample(10)
```

```python
# # drop avg_delivery_delay_days and max_delivery_delay_days
# df = df.drop(columns=['avg_delivery_delay_days', 'max_delivery_delay_days'])

# # remove from numeric_columns
# numeric_columns = numeric_columns.drop(['avg_delivery_delay_days', 'max_delivery_delay_days'])
```

```python
import math
import matplotlib.pyplot as plt
import seaborn as sns

# Nombre total de graphiques à tracer
num_plots = len(numeric_columns)
# Définir le nombre de colonnes souhaité, par exemple 3
num_cols = 3
# Calculer le nombre de lignes nécessaires
num_rows = math.ceil(num_plots / num_cols)

fig, axes = plt.subplots(num_rows, num_cols, figsize=(num_cols * 5, num_rows * 4))
axes = axes.flatten()  # Mettre tous les axes dans un tableau 1D

for idx, col in enumerate(numeric_columns):
    sns.histplot(df[col], kde=True, ax=axes[idx])
    axes[idx].set_title(f'Distribution de {col}')
    axes[idx].set_xlabel('')

# Supprimer les axes inutilisés
for ax in axes[num_plots:]:
    fig.delaxes(ax)

plt.tight_layout()
plt.show()

```

```python
# # Les colonnes max_delivery_delay_days et avg_delivery_delay_days contiennent des valeurs identiques. Nous le vérifions, et si c'est le cas, supprimons une des colonnes.
# print("Les colonnes max_delivery_delay_days et avg_delivery_delay_days contiennent-elles les mêmes valeurs ?")
# sameValues = (df['max_delivery_delay_days'] == df['avg_delivery_delay_days']).all()

# # quelles sont les valeurs différentes entre les deux colonnes ?
# if not sameValues:
#     print("Les colonnes max_delivery_delay_days et avg_delivery_delay_days ne contiennent pas les mêmes valeurs.")
#     print("Valeurs différentes entre les deux colonnes :")
#     print(df.loc[df['max_delivery_delay_days'] != df['avg_delivery_delay_days'], ['max_delivery_delay_days', 'avg_delivery_delay_days']])

# # Suppression de la colonne avg_delivery_delay_days
# if sameValues:
#     print("Les colonnes max_delivery_delay_days et avg_delivery_delay_days contiennent les mêmes valeurs. Nous allons supprimer la colonne avg_delivery delay_days.")
#     df = df.drop(columns=['avg_delivery_delay_days'])
#     numeric_columns = numeric_columns.drop('avg_delivery_delay_days')
```

```python
# Il n'y a que 188 cas où la valeur est différente. Nous supprimons la colonne avg_delivery_delay_days.
# df = df.drop(columns=['avg_delivery_delay_days'])

# on enlève avg_delivery_delay_days de numeric_columns
```

### Analyse des outliers

Nous pouvons observer que certaines variables comme 'total_orders', 'total_spent', et 'max_delivery_delay_days' présentent des valeurs extrêmes. Ces outliers peuvent être légitimes dans le contexte d'un site e-commerce (par exemple, des clients très fidèles ou des commandes très importantes), mais il faudra les prendre en compte lors de la modélisation.


## 4. Analyse des variables catégorielles

```python
# Sélection des colonnes catégorielles
categorical_columns = df.select_dtypes(exclude=['number']).columns
print("Colonnes catégorielles :")
print(categorical_columns)

# Affichage des valeurs uniques pour chaque variable catégorielle
for col in categorical_columns:
    # Seulement si ce n'est pas customer_unique_id
    if col == 'customer_unique_id':
        continue
    print(f"\nValeurs uniques dans {col}:")
    print(df[col].value_counts())
```

```python
# La colonne "last_order_status" ne contient qu'une seule valeur à l'exception de 6 individus, on la supprime
df = df.drop(columns=['last_order_status'])
```

```python
# La colonne "last_payment_type" contient une majorité de "credit_card". Nous allons utiliser 2 valeurs pour cette colonne, credit_card et other
df['last_payment_type'] = df['last_payment_type'].apply(lambda x: 'credit_card' if x == 'credit_card' else 'other')
```

```python
# Colonnes catégorielles sans customer_unique_id
categorical_columns = categorical_columns.drop(['customer_unique_id', 'last_order_status'])

# # Visualisation de la distribution de la variable catégorielle "last_payment_type"
sns.countplot(y=df['last_payment_type'])
plt.title('Distribution de last_payment_type')
plt.xlabel('Nombre d\'occurrences')
plt.show()


# fig, axes = plt.subplots(len(categorical_columns), 1, figsize=(12, 6*len(categorical_columns)))

# for idx, col in enumerate(categorical_columns):
#     sns.countplot(y=df[col], ax=axes[idx])
#     axes[idx].set_title(f'Distribution de {col}')
#     axes[idx].set_xlabel('Nombre d\'occurrences')

# plt.tight_layout()
# plt.show()
```

## 5. Analyse des corrélations

```python
# Calcul de la matrice de corrélation
correlation_matrix = df[numeric_columns].corr()

# Visualisation de la matrice de corrélation
plt.figure(figsize=(12, 10))
sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', vmin=-1, vmax=1, center=0)
plt.title('Matrice de corrélation des variables numériques')
plt.show()

# Sauvegarde de la matrice de corrélation
correlation_matrix.to_csv('data/correlation_matrix.csv')
print("La matrice de corrélation a été sauvegardée dans 'data/correlation_matrix.csv'")
```

```python
df.sample(10)
```

### Analyse des corrélations

On peut observer quelques corrélations intéressantes :
1. Une forte corrélation positive entre 'total_orders' et 'total_spent', ce qui est logique.
2. Une corrélation modérée entre 'avg_delivery_time_days' et 'avg_delivery_delay_days', ce qui suggère que les retards de livraison contribuent significativement au temps de livraison total.
3. Une faible corrélation négative entre 'avg_review_score' et 'avg_delivery_delay_days', indiquant que les retards de livraison peuvent légèrement impacter la satisfaction client.

Ces corrélations seront importantes à considérer lors de la phase de modélisation pour éviter la multicolinéarité et pour choisir les variables les plus pertinentes pour la segmentation.

```python
df.info()
```

# 9. Conclusion et prochaines étapes

"""
### Résumé de l'analyse exploratoire

1. **Données initiales** : Nous avons analysé un jeu de données de 97078 clients d'un site e-commerce, comprenant diverses variables comportementales et transactionnelles.

2. **Préparation des données** :
   - Traitement des valeurs manquantes
   - Suppression des outliers sur les variables clés
   - Simplification des variables catégorielles
   - Feature engineering pour créer des variables plus pertinentes

3. **Variables importantes** :
   - La majorité des clients ont effectué une seule commande
   - Les délais de livraison varient considérablement
   - La satisfaction client (review score) est généralement élevée
   - Les modes de paiement sont dominés par la carte de crédit

4. **Corrélations notables** :
   - Lien entre temps de livraison et satisfaction client
   - Corrélation entre méthode de paiement et montant dépensé
   - Lien entre fréquence d'achat et fidélité

### Prochaines étapes

1. **Modélisation** :
   - Standardisation des variables numériques
   - Application d'algorithmes de clustering (K-means, DBSCAN)
   - Analyse RFM (Récence, Fréquence, Montant)

2. **Segmentation** :
   - Détermination du nombre optimal de segments
   - Caractérisation des segments de clients
   - Validation de la pertinence business des segments

3. **Exploitation** :
   - Développement de stratégies marketing personnalisées par segment
   - Mise en place d'un suivi de l'évolution des segments dans le temps
   - Optimisation des parcours client en fonction des segments

Le dataset nettoyé et augmenté servira de base solide pour la phase de segmentation.
"""

```python
# 8. Préparation du dataset final
# Vérifions qu'il n'y a plus de valeurs manquantes
missing_values = df.isnull().sum()
print("Vérification des valeurs manquantes dans le dataset:")
display(missing_values[missing_values > 0])

# Si nécessaire, supprimons les observations avec des valeurs manquantes
if missing_values.sum() > 0:
    df = df.dropna()
    print(f"Après suppression des valeurs manquantes, nous avons {df.shape[0]} observations.")

# Simplifions la colonne "last_payment_type" en catégories plus pertinentes
df['last_payment_type'] = df['last_payment_type'].apply(lambda x: 'credit_card' if x == 'credit_card' else 'other')

# Création d'une nouvelle colonne pour préserver les données originales
df['payment_type_binary'] = df['last_payment_type'].map({
    'credit_card': 'credit_card'
}).fillna('other')

# Affichage de la distribution des types de paiement
print("Distribution des types de paiement :")
display(df['payment_type_binary'].value_counts(normalize=True))

# Supprimons les colonnes inutiles ou redondantes
columns_to_drop = ['total_orders', 'total_spent']

# Vérifions si les colonnes avg_delivery_delay_days et max_delivery_delay_days sont identiques
if 'avg_delivery_delay_days' in df.columns and 'max_delivery_delay_days' in df.columns:
    similarity = (df['avg_delivery_delay_days'] == df['max_delivery_delay_days']).mean()
    print(f"Les colonnes avg_delivery_delay_days et max_delivery_delay_days sont identiques à {similarity*100:.2f}%")
    if similarity > 0.99:  # Si plus de 99% similaires
        columns_to_drop.append('avg_delivery_delay_days')
        print("La colonne avg_delivery_delay_days sera supprimée car presque identique à max_delivery_delay_days.")
    else:
        print("Les deux colonnes sont conservées car elles contiennent des informations différentes.")

# Suppression des colonnes inutiles
df = df.drop(columns=columns_to_drop, errors='ignore')
print(f"\nLe dataset final contient {df.shape[0]} observations et {df.shape[1]} variables.")
```

```python
# Génération du fichier csv clean pour les modèles de machine learning
df.to_csv('data/clean.csv', index=False)
print("Le dataset nettoyé a été sauvegardé dans 'data/clean.csv'")

# Affichage d'un échantillon du dataset final
df.sample(10)
```

```python
def print_dataset_summary(df):
    print("\nRésumé du dataset final:")
    print(f"- Nombre d'observations: {df.shape[0]:,}")
    print(f"- Nombre de variables: {df.shape[1]}")
    print("\nTypes des variables:")
    display(df.dtypes)
    print("\nAperçu des premières lignes:")
    display(df.head())

print_dataset_summary(df)
```
