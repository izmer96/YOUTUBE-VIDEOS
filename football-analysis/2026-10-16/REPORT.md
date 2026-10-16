# Fixture Probability Ledger — 16–22 Oct 2026 (v2: with Superbet.ro odds)

Full interactive report (all sections, evidence cards, 111 fixture dossiers): `fixture-probability-ledger.html` in this folder.

## Section 1 — Research completion audit

- Fixtures identified: 111; analysed: 111 (every uploaded fixture).
- Unique teams researched: 180; unique current-season matches reviewed: 1542 (2540 team-match records).
- Rating model: 29,478 competitive matches (Mar 2024 – 15 Oct 2026), 1,308 clubs, 48 leagues + cups + UEFA competitions.
- Market anchor: Sofascore odds feed for 75 fixtures, Superbet.ro for 28 (v2), none yet for 8 (listed on Superbet, markets not open).
- Superbet.ro odds captured 2026-10-16 11:08 UTC; 927 prices for 103 fixtures independently re-derived from raw data: 0 discrepancies.
- Backtest (n=2031): model O2.5 Brier 0.2423, market 0.2381, coherent 25/75 blend (used) 0.2384; 1X2 RPS model 0.2041, market 0.1981, used 0.1988.

## Section 2 — Complete probability matrix (final estimate @ Superbet.ro decimal odds)

`n/o` = listed on Superbet, odds not open yet. Value = estimate × Superbet odds − 1.

| Kickoff (UTC) | Comp | Match | O2.5 | O3.5 | BTTS | Home | Draw | Away | xG | Best SB value | Anchor |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Fri 16 Oct 17:00 | SuperLig | Çorum FK v Çaykur Rizespor | 56.9% @1.64 | 34.5% @2.57 | 59.6% @1.55 | 46.1% @2.07 | 25.5% @3.65 | 28.4% @3.35 | 1.69–1.28 | 1 -4.5% | market |
| Fri 16 Oct 18:30 | Bundesliga | Eintracht Frankfurt v 1. FC Köln | 69.1% @1.33 | 47.7% @1.82 | 67.7% @1.35 | 53.4% @1.87 | 22.2% @4.25 | 24.4% @3.60 | 2.14–1.42 | 1 -0.2% | market |
| Fri 16 Oct 18:45 | SerieA | Frosinone v Sassuolo | 65.0% @1.42 | 43.0% @2.02 | 66.9% @1.38 | 39.3% @2.40 | 24.7% @3.75 | 36.0% @2.72 | 1.71–1.63 | 2 -2.1% | market |
| Fri 16 Oct 18:45 | Ligue1 | Le Mans v Toulouse | 55.8% @1.65 | 33.4% @2.55 | 59.6% @1.54 | 30.1% @3.00 | 26.8% @3.55 | 43.1% @2.30 | 1.31–1.61 | 2 -0.9% | market |
| Fri 16 Oct 19:00 | LaLiga | Deportivo de A Coruña v Levante UD | 49.2% @1.87 | 27.4% @3.15 | 53.8% @1.72 | 43.4% @2.10 | 27.1% @3.45 | 29.5% @3.50 | 1.47–1.17 | 2 +3.2% | market |
| Sat 17 Oct 10:30 | SuperLig | Erzurumspor FK v Eyüpspor | 45.8% @2.07 | 24.4% @3.70 | 45.4% @2.05 | 58.9% @1.63 | 25.0% @3.80 | 16.1% @5.35 | 1.72–0.79 | 1 -4.0% | market |
| Sat 17 Oct 11:30 | PL | Everton v Chelsea | 56.0% @1.69 | 33.6% @2.67 | 59.0% @1.59 | 31.6% @3.15 | 25.2% @3.65 | 43.2% @2.17 | 1.33–1.59 | 1 -0.4% | market |
| Sat 17 Oct 12:00 | LaLiga | Espanyol v Atlético Madrid | 52.6% @1.80 | 30.4% @3.00 | 53.0% @1.78 | 20.3% @4.65 | 24.2% @3.90 | 55.5% @1.72 | 0.99–1.79 | 2 -4.5% | market |
| Sat 17 Oct 13:00 | SerieA | Venezia v SSC Napoli | 54.5% @1.71 | 32.1% @2.75 | 54.5% @1.70 | 20.0% @4.55 | 24.2% @3.90 | 55.8% @1.73 | 1.02–1.84 | 2 -3.4% | market |
| Sat 17 Oct 13:00 | SuperLig | Gençlerbirliği v Galatasaray | 62.4% @1.49 | 40.1% @2.20 | 55.0% @1.69 | 14.1% @6.40 | 18.9% @5.00 | 67.0% @1.41 | 0.95–2.27 | 2 -5.5% | market |
| Sat 17 Oct 13:00 | SuperLig | Amed Sportif Faaliyetler v Konyaspor | 49.0% @1.92 | 27.1% @3.25 | 52.0% @1.76 | 50.3% @1.92 | 26.5% @3.45 | 23.2% @4.00 | 1.61–1.02 | 1 -3.4% | market |
| Sat 17 Oct 13:30 | Bundesliga | 1. FC Union Berlin v Borussia Dortmund | 62.0% @1.51 | 39.8% @2.25 | 59.3% @1.58 | 18.3% @5.00 | 22.1% @4.40 | 59.6% @1.59 | 1.10–2.10 | X -2.9% | market |
| Sat 17 Oct 13:30 | Bundesliga | Hamburger SV v VfB Stuttgart | 65.9% @1.41 | 44.0% @2.00 | 65.1% @1.42 | 24.6% @3.85 | 22.6% @4.10 | 52.7% @1.83 | 1.35–2.04 | 2 -3.5% | market |
| Sat 17 Oct 13:30 | Bundesliga | FC Schalke 04 v 1. FSV Mainz 05 | 58.2% @1.61 | 35.8% @2.50 | 60.8% @1.52 | 29.7% @2.95 | 25.2% @3.60 | 45.1% @2.30 | 1.33–1.69 | 2 +3.7% | market |
| Sat 17 Oct 13:30 | Bundesliga | SV Werder Bremen v SC Paderborn 07 | 60.5% @1.54 | 38.1% @2.32 | 60.3% @1.53 | 53.4% @1.82 | 23.0% @4.00 | 23.6% @4.00 | 1.92–1.21 | 1 -2.8% | market |
| Sat 17 Oct 13:30 | Bundesliga | SV 07 Elversberg v FC Augsburg | 64.2% @1.46 | 42.1% @2.12 | 66.2% @1.41 | 40.2% @2.50 | 24.8% @3.75 | 35.0% @2.60 | 1.72–1.59 | 1 +0.4% | market |
| Sat 17 Oct 14:00 | PL | Manchester City v Ipswich Town | 67.6% @1.39 | 46.0% @2.00 | 52.3% @1.80 | 76.3% @1.25 | 14.3% @6.60 | 9.4% @9.40 | 2.65–0.83 | 1 -4.7% | market |
| Sat 17 Oct 14:00 | PL | Brentford v Liverpool FC | 59.5% @1.58 | 37.1% @2.40 | 62.4% @1.49 | 39.7% @2.42 | 25.2% @3.65 | 35.1% @2.75 | 1.59–1.49 | 2 -3.5% | market |
| Sat 17 Oct 14:00 | PL | Fulham v Hull City | 54.7% @1.74 | 32.4% @2.82 | 53.8% @1.73 | 57.6% @1.73 | 23.2% @3.90 | 19.2% @4.55 | 1.88–0.99 | 1 -0.4% | market |
| Sat 17 Oct 14:15 | LaLiga | Villarreal v Elche | 62.1% @1.48 | 39.9% @2.17 | 57.2% @1.64 | 63.3% @1.46 | 20.0% @4.90 | 16.7% @5.90 | 2.18–1.03 | 2 -1.4% | market |
| Sat 17 Oct 15:15 | Ligue1 | RC Strasbourg v Paris Saint-Germain | 69.2% @1.35 | 47.8% @1.88 | 61.6% @1.54 | 15.5% @6.30 | 18.0% @5.40 | 66.5% @1.40 | 1.12–2.45 | 1 -2.3% | market |
| Sat 17 Oct 16:00 | SerieA | Bologna v Inter | 55.5% @1.66 | 33.1% @2.62 | 55.1% @1.70 | 19.2% @5.20 | 24.1% @4.10 | 56.6% @1.62 | 1.02–1.88 | 1 -0.0% | market |
| Sat 17 Oct 16:00 | SuperLig | Fenerbahçe v Alanyaspor | 59.6% @1.57 | 37.2% @2.42 | 49.0% @1.95 | 71.4% @1.30 | 18.1% @5.60 | 10.5% @8.60 | 2.31–0.78 | X +1.2% | market |
| Sat 17 Oct 16:30 | PL | Newcastle United v Aston Villa | 59.2% @1.60 | 36.8% @2.45 | 62.3% @1.51 | 42.5% @2.30 | 25.9% @3.65 | 31.6% @2.92 | 1.66–1.41 | 1 -2.3% | market |
| Sat 17 Oct 16:30 | LaLiga | Real Betis v FC Barcelona | 73.9% @1.26 | 53.6% @1.67 | 66.8% @1.40 | 17.5% @5.60 | 17.5% @5.45 | 64.9% @1.44 | 1.29–2.56 | 1 -1.7% | market |
| Sat 17 Oct 16:30 | Bundesliga | FC Bayern München v RB Leipzig | 83.1% @1.14 | 66.5% @1.40 | 68.6% @1.40 | 76.8% @1.23 | 12.9% @7.70 | 10.2% @9.00 | 3.30–1.24 | X -0.4% | market |
| Sat 17 Oct 18:45 | SerieA | AS Roma v Genoa | 52.0% @1.73 | 29.8% @2.82 | 49.6% @1.85 | 61.2% @1.54 | 23.1% @4.35 | 15.8% @5.80 | 1.90–0.86 | X +0.3% | market |
| Sat 17 Oct 18:45 | Ligue1 | Lille v Stade Brestois | 54.7% @1.68 | 32.4% @2.67 | 56.7% @1.63 | 50.7% @1.88 | 25.4% @3.75 | 24.0% @3.90 | 1.74–1.13 | 1 -4.8% | market |
| Sat 17 Oct 18:45 | Ligue1 | Troyes v RC Lens | 59.2% @1.58 | 36.8% @2.40 | 60.0% @1.55 | 24.8% @3.85 | 23.9% @3.85 | 51.3% @1.87 | 1.23–1.84 | 2 -4.1% | market |
| Sat 17 Oct 19:00 | LaLiga | Valencia v Athletic Club | 45.1% @2.10 | 23.8% @3.75 | 51.2% @1.85 | 31.0% @3.30 | 28.9% @3.25 | 40.2% @2.27 | 1.14–1.34 | 1 +2.2% | market |
| Sun 18 Oct 10:30 | SerieA | Udinese v Lecce | 47.3% @2.05 | 25.7% @3.55 | 50.4% @1.88 | 51.1% @1.90 | 26.8% @3.50 | 22.1% @4.15 | 1.60–0.97 | 1 -2.9% | market |
| Sun 18 Oct 10:30 | SuperLig | Kasımpaşa v Samsunspor | 47.4% @2.00 | 25.7% @3.50 | 52.8% @1.77 | 37.9% @2.50 | 27.7% @3.35 | 34.4% @2.77 | 1.32–1.25 | 2 -4.7% | market |
| Sun 18 Oct 12:00 | LaLiga | Osasuna v Real Racing Club | 59.1% @1.64 | 36.7% @2.55 | 60.8% @1.56 | 49.6% @2.05 | 25.2% @3.65 | 25.3% @3.50 | 1.81–1.25 | 1 +1.6% | market |
| Sun 18 Oct 13:00 | PL | Leeds United v Manchester United | 57.6% @1.65 | 35.2% @2.55 | 61.0% @1.54 | 41.1% @2.37 | 26.1% @3.55 | 32.8% @2.87 | 1.59–1.40 | 1 -2.5% | market |
| Sun 18 Oct 13:00 | PL | Brighton & Hove Albion v Crystal Palace | 60.2% @1.55 | 37.8% @2.35 | 56.8% @1.65 | 61.0% @1.55 | 21.2% @4.50 | 17.8% @5.40 | 2.08–1.04 | 2 -3.9% | market |
| Sun 18 Oct 13:00 | PL | Bournemouth v Sunderland | 52.2% @1.82 | 30.0% @3.00 | 55.5% @1.68 | 47.7% @2.12 | 26.5% @3.50 | 25.8% @3.40 | 1.62–1.14 | 1 +1.1% | market |
| Sun 18 Oct 13:00 | SerieA | Fiorentina v Como | 55.6% @1.66 | 33.2% @2.60 | 59.0% @1.57 | 27.8% @3.40 | 26.6% @3.65 | 45.6% @2.07 | 1.25–1.65 | X -2.9% | market |
| Sun 18 Oct 13:00 | Ligue1 | Angers v Olympique de Marseille | 59.0% @1.61 | 36.6% @2.47 | 60.8% @1.53 | 27.5% @3.25 | 24.5% @3.70 | 48.0% @2.12 | 1.29–1.77 | 2 +1.7% | market |
| Sun 18 Oct 13:00 | SuperLig | Kocaelispor v Göztepe | 49.1% @1.90 | 27.2% @3.25 | 54.2% @1.71 | 33.9% @2.87 | 27.4% @3.40 | 38.7% @2.37 | 1.27–1.37 | 1 -2.6% | market |
| Sun 18 Oct 13:30 | Bundesliga | Bayer 04 Leverkusen v SC Freiburg | 63.8% @1.48 | 41.7% @2.17 | 62.1% @1.50 | 56.2% @1.73 | 22.1% @4.20 | 21.6% @4.25 | 2.06–1.22 | 1 -2.7% | market |
| Sun 18 Oct 14:15 | LaLiga | Celta Vigo v Deportivo Alavés | 42.0% @2.22 | 21.3% @4.10 | 47.6% @1.95 | 43.6% @2.17 | 28.3% @3.30 | 28.0% @3.50 | 1.34–1.02 | 2 -2.0% | market |
| Sun 18 Oct 15:15 | Ligue1 | Lorient v AS Monaco | 50.0% @1.92 | 28.0% @3.25 | 54.5% @1.75 | 30.4% @3.55 | 26.9% @3.40 | 42.7% @2.10 | 1.20–1.47 | 1 +8.0% | market |
| Sun 18 Oct 15:15 | Ligue1 | Paris FC v Stade Rennais | 57.1% @1.65 | 34.7% @2.57 | 60.3% @1.54 | 42.7% @2.32 | 25.7% @3.55 | 31.6% @2.95 | 1.61–1.36 | 1 -0.8% | market |
| Sun 18 Oct 15:15 | Ligue1 | Le Havre v Auxerre | 51.4% @1.87 | 29.3% @3.15 | 56.2% @1.69 | 40.8% @2.30 | 27.6% @3.40 | 31.6% @3.10 | 1.47–1.26 | 2 -2.1% | market |
| Sun 18 Oct 15:30 | PL | Nottingham Forest v Arsenal | 48.7% @1.92 | 26.9% @3.30 | 48.1% @1.95 | 16.5% @5.55 | 24.6% @3.90 | 58.9% @1.62 | 0.84–1.78 | X -4.1% | market |
| Sun 18 Oct 15:30 | Bundesliga | Borussia M'gladbach v TSG Hoffenheim | 66.6% @1.41 | 44.8% @2.00 | 67.7% @1.39 | 34.1% @3.05 | 23.6% @4.00 | 42.2% @2.12 | 1.62–1.81 | 1 +4.1% | market |
| Sun 18 Oct 16:00 | SerieA | AC Milan v Atalanta | 54.9% @1.74 | 32.5% @2.80 | 56.5% @1.68 | 51.4% @1.82 | 25.0% @3.75 | 23.6% @4.25 | 1.75–1.12 | 2 +0.4% | market |
| Sun 18 Oct 16:00 | SuperLig | Başakşehir FK v Gaziantep FK | 58.6% @1.60 | 36.2% @2.47 | 57.7% @1.61 | 56.7% @1.68 | 23.1% @4.00 | 20.2% @4.55 | 1.95–1.09 | 1 -4.7% | market |
| Sun 18 Oct 16:30 | LaLiga | Málaga CF v Real Sociedad | 53.0% @1.78 | 30.7% @2.92 | 57.3% @1.65 | 31.1% @3.20 | 27.0% @3.50 | 41.9% @2.20 | 1.28–1.52 | 1 -0.5% | market |
| Sun 18 Oct 18:45 | SerieA | Juventus v Lazio | 49.6% @1.92 | 27.7% @3.30 | 50.0% @1.90 | 56.8% @1.69 | 24.9% @3.80 | 18.3% @5.00 | 1.76–0.90 | 1 -4.0% | market |
| Sun 18 Oct 18:45 | Ligue1 | Olympique Lyonnais v Nice | 57.5% @1.65 | 35.1% @2.60 | 56.3% @1.66 | 57.4% @1.69 | 22.9% @4.10 | 19.7% @4.60 | 1.94–1.06 | 1 -3.0% | market |
| Sun 18 Oct 19:00 | LaLiga | Real Madrid v Sevilla | 65.9% @1.42 | 44.0% @2.07 | 51.4% @1.95 | 75.4% @1.22 | 14.6% @6.90 | 10.0% @11.00 | 2.57–0.82 | 2 +9.7% | market |
| Mon 19 Oct 16:30 | SerieA | Monza v Cagliari | 45.2% @2.10 | 23.9% @3.70 | 51.8% @1.82 | 38.1% @2.42 | 29.8% @3.20 | 32.1% @3.10 | 1.30–1.18 | 2 -0.6% | market |
| Mon 19 Oct 17:00 | SuperLig | Trabzonspor v Beşiktaş JK | 59.2% @1.57 | 36.8% @2.40 | 62.1% @1.49 | 32.6% @2.87 | 25.5% @3.65 | 41.9% @2.27 | 1.43–1.64 | 2 -4.8% | market |
| Mon 19 Oct 18:45 | SerieA | Parma v Torino | 40.6% @2.37 | 20.2% @4.45 | 47.6% @2.00 | 30.9% @3.20 | 30.1% @3.05 | 39.0% @2.42 | 1.07–1.23 | 1 -1.1% | market |
| Mon 19 Oct 19:00 | PL | Tottenham Hotspur v Coventry City | 58.9% @1.58 | 36.5% @2.45 | 55.4% @1.72 | 61.8% @1.49 | 21.9% @4.65 | 16.2% @5.90 | 2.07–0.98 | X +2.0% | market |
| Mon 19 Oct 19:00 | LaLiga | Getafe v Rayo Vallecano | 37.0% @2.62 | 17.6% @5.15 | 45.0% @2.15 | 32.9% @2.90 | 31.6% @3.00 | 35.6% @2.70 | 1.06–1.11 | O2.5 -2.9% | market |
| Tue 20 Oct 16:45 | UCL | Sabah FK v Borussia Dortmund | 65.7% @1.42 | 43.8% @2.05 | 55.6% @1.74 | 13.1% @8.30 | 16.5% @5.90 | 70.4% @1.30 | 0.95–2.43 | 1 +8.7% | market |
| Tue 20 Oct 16:45 | UCL | Fenerbahçe v SK Slavia Praha | 58.6% @1.63 | 36.2% @2.52 | 58.2% @1.65 | 55.4% @1.68 | 23.4% @4.10 | 21.2% @4.70 | 1.92–1.12 | 2 -0.1% | market |
| Tue 20 Oct 19:00 | UCL | Paris Saint-Germain v FC Barcelona | 76.8% @1.22 | 57.5% @1.56 | 75.7% @1.23 | 42.9% @2.45 | 21.6% @4.10 | 35.4% @2.52 | 2.12–1.93 | 1 +5.1% | market |
| Tue 20 Oct 19:00 | UCL | Manchester City v AEK Athens | 72.7% @1.28 | 52.1% @1.72 | 39.2% @2.57 | 88.4% @1.07 | 8.9% @13.00 | 2.7% @27.00 | 3.26–0.52 | X +15.3% | market |
| Tue 20 Oct 19:00 | UCL | Liverpool FC v Villarreal | 62.6% @1.53 | 40.4% @2.32 | 57.6% @1.65 | 63.8% @1.51 | 21.0% @4.60 | 15.2% @5.65 | 2.22–1.01 | X -3.3% | market |
| Tue 20 Oct 19:00 | UCL | VfB Stuttgart v Atlético Madrid | 62.2% @1.55 | 40.0% @2.35 | 64.8% @1.48 | 32.6% @2.87 | 25.5% @3.70 | 41.9% @2.30 | 1.50–1.71 | O2.5 -3.5% | market |
| Tue 20 Oct 19:00 | UCL | SSC Napoli v Bodø/Glimt | 63.4% @1.49 | 41.3% @2.22 | 61.8% @1.57 | 56.7% @1.60 | 22.6% @4.45 | 20.7% @4.90 | 2.07–1.20 | 2 +1.2% | market |
| Tue 20 Oct 19:00 | UCL | FC Porto v PSV Eindhoven | 60.8% @1.57 | 38.4% @2.40 | 59.4% @1.57 | 56.2% @1.80 | 22.2% @4.00 | 21.5% @4.10 | 1.98–1.16 | 1 +1.2% | market |
| Tue 20 Oct 19:00 | UCL | AS Roma v ŠK Slovan Bratislava | 71.0% @1.31 | 50.0% @1.80 | 48.3% @1.90 | 82.5% @1.16 | 11.2% @8.30 | 6.3% @13.00 | 2.95–0.72 | 1 -4.3% | market |
| Wed 21 Oct 16:45 | UCL | Como v Manchester United | 57.1% @1.64 | 34.7% @2.55 | 60.5% @1.55 | 38.9% @2.30 | 25.7% @3.65 | 35.4% @2.92 | 1.53–1.45 | 2 +3.4% | market |
| Wed 21 Oct 16:45 | UCL | Lille v Galatasaray | 56.8% @1.65 | 34.4% @2.57 | 59.9% @1.55 | 45.1% @2.25 | 26.0% @3.55 | 28.8% @3.05 | 1.66–1.29 | 1 +1.6% | market |
| Wed 21 Oct 19:00 | UCL | Real Madrid v RB Leipzig | 74.7% @1.28 | 54.7% @1.70 | 62.5% @1.56 | 73.0% @1.27 | 16.0% @6.50 | 11.0% @8.60 | 2.83–1.07 | X +3.7% | market |
| Wed 21 Oct 19:00 | UCL | FC Bayern München v Arsenal | 59.5% @1.61 | 37.1% @2.45 | 62.6% @1.52 | 42.3% @2.20 | 25.9% @3.60 | 31.7% @3.15 | 1.66–1.42 | 2 -0.1% | market |
| Wed 21 Oct 19:00 | UCL | Inter v Shakhtar Donetsk | 69.7% @1.32 | 48.5% @1.82 | 54.2% @1.75 | 76.5% @1.22 | 14.4% @7.20 | 9.1% @10.00 | 2.74–0.86 | X +3.4% | market |
| Wed 21 Oct 19:00 | UCL | Aston Villa v Viking FK | 71.0% @1.33 | 50.0% @1.82 | 57.6% @1.68 | 74.4% @1.25 | 16.0% @6.40 | 9.6% @9.90 | 2.74–0.94 | X +2.6% | market |
| Wed 21 Oct 19:00 | UCL | Real Betis v Feyenoord | 66.8% @1.42 | 45.0% @2.05 | 62.9% @1.53 | 60.0% @1.54 | 20.2% @4.75 | 19.8% @5.20 | 2.22–1.22 | 2 +3.0% | market |
| Wed 21 Oct 19:00 | UCL | Sporting CP v LASK | 69.0% @1.36 | 47.5% @1.90 | 54.8% @1.70 | 75.1% @1.28 | 14.8% @6.40 | 10.1% @8.60 | 2.67–0.89 | 1 -3.9% | market |
| Wed 21 Oct 19:00 | UCL | Club Brugge KV v RC Lens | 62.7% @1.61 | 40.5% @2.47 | 63.2% @1.53 | 47.7% @2.15 | 22.6% @3.70 | 29.8% @3.15 | 1.83–1.40 | 1 +2.5% | market |
| Thu 22 Oct 14:30 | UECL | FC Kairat Almaty v Panathinaikos FC | 50.5% @1.83 | 28.5% @3.05 | 52.8% @1.75 | 22.6% @4.10 | 25.7% @3.70 | 51.7% @1.85 | 1.03–1.67 | 2 -4.4% | Superbet |
| Thu 22 Oct 16:45 | UEL | Juventus v Stade Rennais | 56.1% @1.75 | 33.7% @2.85 | 54.1% @1.80 | 59.4% @1.62 | 22.4% @4.15 | 18.2% @5.15 | 1.95–0.99 | O2.5 -1.8% | Superbet |
| Thu 22 Oct 16:45 | UEL | OFI Crete v Bayer 04 Leverkusen | 65.8% @1.40 | 43.9% @2.00 | 52.5% @1.78 | 10.0% @9.60 | 15.8% @6.30 | 74.2% @1.26 | 0.84–2.55 | X -0.4% | Superbet |
| Thu 22 Oct 16:45 | UEL | SK Sturm Graz v Olympique de Marseille | 57.4% @1.71 | 35.0% @2.72 | 59.7% @1.62 | 26.4% @3.55 | 25.4% @3.60 | 48.2% @2.02 | 1.24–1.74 | O2.5 -1.9% | Superbet |
| Thu 22 Oct 16:45 | UEL | Lech Poznań v Sunderland | 54.3% @1.80 | 32.0% @3.00 | 54.5% @1.82 | 21.9% @4.85 | 23.4% @4.10 | 54.7% @1.66 | 1.05–1.80 | 1 +6.5% | Superbet |
| Thu 22 Oct 16:45 | UEL | GNK Dinamo Zagreb v NEC Nijmegen | 62.7% @1.55 | 40.5% @2.35 | 62.2% @1.56 | 53.8% @1.74 | 22.9% @4.10 | 23.2% @4.35 | 1.99–1.25 | 2 +1.0% | Superbet |
| Thu 22 Oct 16:45 | UEL | Royale Union Saint-Gilloise v Hapoel Be'er Sheva | 61.6% @1.50 | 39.3% @2.25 | 51.3% @1.85 | 71.0% @1.31 | 17.3% @5.75 | 11.7% @8.30 | 2.34–0.84 | X -0.6% | Superbet |
| Thu 22 Oct 16:45 | UEL | FC Ararat-Armenia v AZ Alkmaar | 62.4% @1.57 | 40.1% @2.40 | 56.5% @1.70 | 15.1% @6.00 | 20.0% @4.55 | 64.8% @1.50 | 0.99–2.23 | O2.5 -2.1% | Superbet |
| Thu 22 Oct 16:45 | UEL | Ferencváros TC v Torreense | 57.9% @1.62 | 35.5% @2.55 | 50.2% @1.92 | 68.0% @1.37 | 18.8% @5.20 | 13.2% @7.40 | 2.17–0.84 | X -2.1% | Superbet |
| Thu 22 Oct 16:45 | UECL | FK Jablonec v Brighton & Hove Albion | 62.5% @1.52 | 40.3% @2.27 | 53.9% @1.70 | 12.7% @6.60 | 18.3% @4.90 | 68.9% @1.43 | 0.90–2.32 | 2 -1.4% | Superbet |
| Thu 22 Oct 16:45 | UECL | FK Crvena zvezda v FC København | 58.7% @1.70 | 36.3% @2.70 | 62.0% @1.58 | 38.2% @2.45 | 25.9% @3.55 | 35.9% @2.77 | 1.55–1.50 | O2.5 -0.2% | Superbet |
| Thu 22 Oct 16:45 | UECL | Trabzonspor v Heart of Midlothian | 54.3% @n/o | 31.9% @n/o | 54.8% @n/o | 54.5% @n/o | 24.2% @n/o | 21.3% @n/o | 1.80–1.05 | n/o | model only |
| Thu 22 Oct 16:45 | UECL | Getafe v FC Lugano | 42.6% @n/o | 21.8% @n/o | 47.9% @n/o | 45.7% @n/o | 28.3% @n/o | 26.0% @n/o | 1.40–0.99 | n/o | model only |
| Thu 22 Oct 16:45 | UECL | Pafos FC v Riga FC | 55.2% @1.75 | 32.9% @2.85 | 52.7% @1.83 | 60.5% @1.57 | 22.2% @4.25 | 17.3% @5.55 | 1.95–0.94 | O2.5 -3.4% | Superbet |
| Thu 22 Oct 16:45 | UECL | FC Nordsjælland v CSKA Sofia | 59.9% @1.62 | 37.5% @2.52 | 55.4% @1.72 | 63.0% @1.53 | 20.8% @4.45 | 16.2% @5.65 | 2.12–0.98 | O2.5 -3.0% | Superbet |
| Thu 22 Oct 16:45 | UECL | FK Kauno Žalgiris v SK Brann | 60.4% @n/o | 38.0% @n/o | 55.9% @n/o | 16.1% @n/o | 20.9% @n/o | 63.1% @n/o | 0.99–2.13 | n/o | model only |
| Thu 22 Oct 16:45 | UECL | FC Iberia 1999 v Mjällby AIF | 52.3% @n/o | 30.1% @n/o | 50.4% @n/o | 16.8% @n/o | 23.1% @n/o | 60.1% @n/o | 0.89–1.88 | n/o | model only |
| Thu 22 Oct 16:45 | UECL | Inter Club d'Escaldes v Universitatea Craiova | 49.5% @1.95 | 27.6% @3.30 | 49.5% @1.95 | 18.1% @5.40 | 24.6% @3.85 | 57.3% @1.65 | 0.89–1.76 | 1 -2.2% | Superbet |
| Thu 22 Oct 19:00 | UEL | Bournemouth v AC Milan | 56.0% @1.72 | 33.7% @2.77 | 58.7% @1.61 | 46.7% @2.20 | 25.4% @3.60 | 27.9% @3.15 | 1.68–1.25 | 1 +2.7% | Superbet |
| Thu 22 Oct 19:00 | UEL | Omonia Nicosia v Benfica | 56.9% @1.66 | 34.5% @2.65 | 52.4% @1.85 | 15.9% @6.50 | 20.7% @4.75 | 63.4% @1.45 | 0.92–2.05 | 1 +3.2% | Superbet |
| Thu 22 Oct 19:00 | UEL | Beşiktaş JK v Crystal Palace | 58.2% @1.59 | 35.9% @2.45 | 61.2% @1.52 | 38.6% @2.20 | 25.1% @3.75 | 36.4% @3.05 | 1.54–1.49 | 2 +10.9% | Superbet |
| Thu 22 Oct 19:00 | UEL | Celtic v Celta Vigo | 51.8% @1.80 | 29.7% @2.95 | 56.5% @1.66 | 32.1% @3.00 | 27.2% @3.50 | 40.8% @2.32 | 1.28–1.47 | 1 -3.8% | Superbet |
| Thu 22 Oct 19:00 | UEL | TSG Hoffenheim v Olympique Lyonnais | 60.4% @1.55 | 38.0% @2.35 | 62.7% @1.50 | 42.3% @2.05 | 24.6% @3.85 | 33.1% @3.30 | 1.67–1.45 | 2 +9.1% | Superbet |
| Thu 22 Oct 19:00 | UEL | Lillestrøm SK v Real Sociedad | 58.1% @1.63 | 35.7% @2.55 | 56.2% @1.73 | 20.0% @5.50 | 21.9% @4.50 | 58.1% @1.54 | 1.06–1.96 | 1 +9.9% | Superbet |
| Thu 22 Oct 19:00 | UEL | Olympiacos FC v AC Sparta Praha | 51.7% @1.80 | 29.6% @3.00 | 50.6% @1.83 | 58.8% @1.62 | 23.7% @4.00 | 17.5% @5.30 | 1.84–0.90 | 1 -4.7% | Superbet |
| Thu 22 Oct 19:00 | UEL | NK Celje v Red Bull Salzburg | 57.4% @1.73 | 35.0% @2.77 | 59.2% @1.66 | 25.8% @3.90 | 24.9% @3.75 | 49.3% @1.90 | 1.22–1.76 | 1 +0.7% | Superbet |
| Thu 22 Oct 19:00 | UEL | Jagiellonia Białystok v RSC Anderlecht | 54.4% @1.77 | 32.0% @2.87 | 58.5% @1.63 | 31.7% @3.05 | 26.8% @3.50 | 41.5% @2.30 | 1.32–1.54 | 1 -3.3% | Superbet |
| Thu 22 Oct 19:00 | UEL | FC Viktoria Plzeň v Levski Sofia | 54.3% @1.71 | 32.0% @2.75 | 55.4% @1.71 | 53.3% @1.72 | 24.7% @3.90 | 22.0% @4.65 | 1.78–1.07 | 2 +2.3% | Superbet |
| Thu 22 Oct 19:00 | UECL | AFC Ajax v Atalanta | 57.1% @1.75 | 34.7% @2.85 | 60.5% @1.63 | 37.7% @2.47 | 25.6% @3.60 | 36.7% @2.70 | 1.50–1.48 | O2.5 -0.0% | Superbet |
| Thu 22 Oct 19:00 | UECL | AS Monaco v SC Freiburg | 58.6% @1.64 | 36.2% @2.55 | 61.4% @1.55 | 43.3% @2.27 | 25.3% @3.70 | 31.4% @2.95 | 1.66–1.38 | 1 -1.8% | Superbet |
| Thu 22 Oct 19:00 | UECL | Sporting Braga v KAA Gent | 49.6% @1.85 | 27.7% @3.10 | 51.3% @1.78 | 53.5% @1.82 | 25.4% @3.75 | 21.1% @4.30 | 1.69–0.97 | 1 -2.7% | Superbet |
| Thu 22 Oct 19:00 | UECL | FC Midtjylland v Sint-Truidense VV | 60.7% @1.59 | 38.4% @2.42 | 60.9% @1.55 | 53.3% @1.85 | 23.9% @3.85 | 22.7% @4.00 | 1.93–1.21 | 1 -1.3% | Superbet |
| Thu 22 Oct 19:00 | UECL | FC Thun v HNK Hajduk Split | 61.2% @n/o | 38.9% @n/o | 63.5% @n/o | 40.0% @n/o | 24.6% @n/o | 35.4% @n/o | 1.63–1.53 | n/o | model only |
| Thu 22 Oct 19:00 | UECL | Lincoln Red Imps v FC Twente | 69.6% @n/o | 48.3% @n/o | 51.7% @n/o | 7.6% @n/o | 13.8% @n/o | 78.6% @n/o | 0.79–2.80 | n/o | model only |
| Thu 22 Oct 19:00 | UECL | FK Borac Banja Luka v Kuopion Palloseura | 51.1% @n/o | 29.0% @n/o | 54.8% @n/o | 46.0% @n/o | 26.3% @n/o | 27.7% @n/o | 1.56–1.16 | n/o | model only |
| Thu 22 Oct 19:00 | UECL | AGF v KF Egnatia | 58.1% @n/o | 35.6% @n/o | 54.4% @n/o | 62.1% @n/o | 21.5% @n/o | 16.4% @n/o | 2.05–0.96 | n/o | model only |

## Section 8 — Overall master ranking (top 40 by final probability)

| # | Fixture | Outcome | Estimate | Model | Market anchor | Superbet odds | Value | Reliability | Correlated with |
|---:|---|---|---:|---:|---:|---:|---:|---|---|
| 1 | Manchester City v AEK Athens | Home Win | 88.4% | 77.3% | 90.0% | 1.07 | -5.4% | Low |  |
| 2 | FC Bayern München v RB Leipzig | Over 2.5 | 83.1% | 78.9% | 82.8% | 1.14 | -5.3% | High |  |
| 3 | AS Roma v ŠK Slovan Bratislava | Home Win | 82.5% | 80.8% | 81.8% | 1.16 | -4.3% | High |  |
| 4 | Lincoln Red Imps v FC Twente | Away Win | 78.6% | 78.6% | – | n/o | – | Low |  |
| 5 | FC Bayern München v RB Leipzig | Home Win | 76.8% | 74.0% | 77.5% | 1.23 | -5.5% | High | #2 |
| 6 | Paris Saint-Germain v FC Barcelona | Over 2.5 | 76.8% | 71.4% | 78.0% | 1.22 | -6.3% | Medium |  |
| 7 | Inter v Shakhtar Donetsk | Home Win | 76.5% | 69.5% | 78.1% | 1.22 | -6.6% | Medium |  |
| 8 | Manchester City v Ipswich Town | Home Win | 76.3% | 73.3% | 76.7% | 1.25 | -4.7% | High |  |
| 9 | Paris Saint-Germain v FC Barcelona | BTTS Yes | 75.7% | 70.6% | 75.0% | 1.23 | -6.8% | High | #6 |
| 10 | Real Madrid v Sevilla | Home Win | 75.4% | 71.5% | 76.3% | 1.22 | -8.0% | High |  |
| 11 | Sporting CP v LASK | Home Win | 75.1% | 74.5% | 74.2% | 1.28 | -3.9% | High |  |
| 12 | Real Madrid v RB Leipzig | Over 2.5 | 74.7% | 71.4% | 76.2% | 1.28 | -4.4% | High |  |
| 13 | Aston Villa v Viking FK | Home Win | 74.4% | 68.2% | 75.6% | 1.25 | -7.0% | Medium |  |
| 14 | OFI Crete v Bayer 04 Leverkusen | Away Win | 74.2% | 69.7% | 75.1% | 1.26 | -6.5% | Medium |  |
| 15 | Real Betis v FC Barcelona | Over 2.5 | 73.9% | 67.4% | 76.2% | 1.26 | -6.9% | Medium |  |
| 16 | Real Madrid v RB Leipzig | Home Win | 73.0% | 66.7% | 74.3% | 1.27 | -7.3% | Medium | #12 |
| 17 | Manchester City v AEK Athens | Over 2.5 | 72.7% | 62.9% | 76.2% | 1.28 | -7.0% | Low | #1 |
| 18 | Fenerbahçe v Alanyaspor | Home Win | 71.4% | 68.3% | 71.6% | 1.30 | -7.1% | High |  |
| 19 | Royale Union Saint-Gilloise v Hapoel Be'er Sheva | Home Win | 71.0% | 66.0% | 72.2% | 1.31 | -7.0% | Low |  |
| 20 | Aston Villa v Viking FK | Over 2.5 | 71.0% | 67.7% | 71.8% | 1.33 | -5.6% | High | #13 |
| 21 | AS Roma v ŠK Slovan Bratislava | Over 2.5 | 71.0% | 66.3% | 72.9% | 1.31 | -7.0% | Medium | #3 |
| 22 | Sabah FK v Borussia Dortmund | Away Win | 70.4% | 59.3% | 72.7% | 1.30 | -8.5% | Low |  |
| 23 | Inter v Shakhtar Donetsk | Over 2.5 | 69.7% | 62.3% | 71.8% | 1.32 | -7.9% | Medium | #7 |
| 24 | Lincoln Red Imps v FC Twente | Over 2.5 | 69.6% | 69.6% | – | n/o | – | Low | #4 |
| 25 | RC Strasbourg v Paris Saint-Germain | Over 2.5 | 69.2% | 62.9% | 71.8% | 1.35 | -6.6% | Medium |  |
| 26 | Eintracht Frankfurt v 1. FC Köln | Over 2.5 | 69.1% | 60.1% | 71.8% | 1.33 | -8.1% | Low |  |
| 27 | Sporting CP v LASK | Over 2.5 | 69.0% | 63.7% | 71.8% | 1.36 | -6.2% | Medium | #11 |
| 28 | FK Jablonec v Brighton & Hove Albion | Away Win | 68.9% | 75.6% | 66.3% | 1.43 | -1.4% | Medium |  |
| 29 | FC Bayern München v RB Leipzig | BTTS Yes | 68.6% | 66.1% | 68.8% | 1.40 | -4.0% | High | #2 |
| 30 | Ferencváros TC v Torreense | Home Win | 68.0% | 63.7% | 69.0% | 1.37 | -6.8% | Low |  |
| 31 | Eintracht Frankfurt v 1. FC Köln | BTTS Yes | 67.7% | 59.0% | 68.8% | 1.35 | -8.6% | Medium | #26 |
| 32 | Borussia M'gladbach v TSG Hoffenheim | BTTS Yes | 67.7% | 62.9% | 68.8% | 1.39 | -6.0% | Medium |  |
| 33 | Manchester City v Ipswich Town | Over 2.5 | 67.6% | 63.2% | 70.1% | 1.39 | -6.0% | Medium | #8 |
| 34 | Gençlerbirliği v Galatasaray | Away Win | 67.0% | 56.6% | 70.9% | 1.41 | -5.5% | Low |  |
| 35 | Frosinone v Sassuolo | BTTS Yes | 66.9% | 58.8% | 68.8% | 1.38 | -7.7% | Medium |  |
| 36 | Real Betis v FC Barcelona | BTTS Yes | 66.8% | 65.4% | 66.3% | 1.40 | -6.5% | High | #15 |
| 37 | Real Betis v Feyenoord | Over 2.5 | 66.8% | 62.2% | 68.2% | 1.42 | -5.2% | Medium |  |
| 38 | Borussia M'gladbach v TSG Hoffenheim | Over 2.5 | 66.6% | 61.0% | 68.2% | 1.41 | -6.1% | Medium | #32 |
| 39 | RC Strasbourg v Paris Saint-Germain | Away Win | 66.5% | 62.8% | 67.6% | 1.40 | -6.9% | High | #25 |
| 40 | FC Bayern München v RB Leipzig | Over 3.5 | 66.5% | 60.3% | 70.1% | 1.40 | -7.0% | Medium | #2 |

Probabilities are estimates for 90 minutes plus stoppage time, not guarantees. Odds move; check live prices. Selections from the same fixture are correlated.
