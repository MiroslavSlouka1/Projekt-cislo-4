# Engeto-4-projekt
Čtvrtý projekt na Python Akademii od Engeta
## Popis projektu
V tomto projetu vytářím databázové tabulky a SQL scripty pro zodpovězení výzkumných otázek.
## Vytvoření tabulek
V krocích 1 až 4 se vytvoří tabulka ```t_Miroslav_Slouka_project_SQL_primary_final```  

V kroku 5 se vytvoří tabulka ```t_miroslav_slouka_project_SQL_secondary_final```
## Výstupy výzkumných otázek
Otázka číslo 1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

Seznam odvětví kde mzda nejvíce klesala:

    2013 Q4	Peněžnictví a pojišťovnictví

    2013 Q4	Výroba a rozvod elektřiny, plynu, tepla a klimatiz. vzduchu

    2013 Q1	Peněžnictví a pojišťovnictví

    2020 Q2	Ubytování, stravování a pohostinství

    2020 Q2  Činnosti v oblasti nemovitostí

    2020 Q1	Činnosti v oblasti nemovitostí

    2010 Q1	Profesní, vědecké a technické činnosti

Otázka číslo 2: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

    Nejvíce mléka si mohlo v roce 2006 Q1 zakoupit odvětví	"Peněžnictví a pojišťovnictví" -  3 054 litrů
    
    Nejvíce chleba si mohlo v roce 2006 Q1 zakoupit odvětví	"Peněžnictví a pojišťovnictví" -  2 949 kilogramů 

    Nejméně mléka si mohlo v roce 2006 Q1 zakoupit odvětví	"Ubytování, stravování a pohostinství" - 735 litrů
    
    Nejméně cleba si mohlo v roce 2006 Q1 zakoupit odvětví	"Ubytování, stravování a pohostinství" - 710 kilogramů

Otázka číslo 3: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

    Nejméně zdražila Rajská jablka červená kulatá v roce 2007

Otázka číslo 4: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

    V roce 2007 nárůst cen potravin výrazně vyšší než růst mezd. 

Otázka číslo 5: Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?     



    
## Ukázka programu

Výsledky hlasování pro okres Benešov

Spuštění programu:
``` 
python Elections_Scraper.py 'https://volby.cz/pls/ps2017nss/ps32?xjazyk=CZ&xkraj=2&xnumnuts=2101' 'vysledky_benesov.csv'
```

Průběh stahování:

``` Stahuji data z vybraneho URL: https://volby.cz/pls/ps2017nss/ps32?xjazyk=CZ&xkraj=2&xnumnuts=2101 ```

během stahování se zobrazuji "*"

```
********************
**
```

po stažení dat se uloží do souboru a program se ukončí

```
Ukladam data do souboru:  vysledky_benesov.csv
Ukoncuji program Election_Scraper
```

Ukázka výstupu:
```
code,location,registered,envelopes,valid,Občanská demokratická strana,Řád národa - Vlastenecká unie,CESTA ODPOVĚDNÉ SPOLEČNOSTI,Česká str.sociálně demokrat.,Radostné Česko
529303,Benešov,13104,8485,8437,1052,10,2,624,3,802,597,109,35,112,6,11,948,3,6,414,2577,3,21,314,5,58,17,16,682,10
532568,Bernartice,191,148,148,4,0,0,17,0,6,7,1,4,0,0,0,7,0,0,3,39,0,0,37,0,3,0,0,20,0
530743,Bílkovice,170,121,118,7,0,0,15,0,8,18,0,2,0,0,0,3,0,0,2,47,1,0,6,0,0,0,0,9,0
```

