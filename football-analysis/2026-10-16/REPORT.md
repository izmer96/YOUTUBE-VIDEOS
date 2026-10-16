# Fixture Probability Ledger — 16–22 Oct 2026

Full interactive report (all sections, evidence cards, 111 fixture dossiers): `fixture-probability-ledger.html` in this folder.

## Section 1 — Research completion audit

- Fixtures identified: 111; analysed: 111 (every uploaded fixture).
- Unique teams researched: 180; unique current-season matches reviewed: 1542 (2540 team-match records).
- Rating model: 29,478 competitive matches (Mar 2024 – 15 Oct 2026), 1,308 clubs, 48 leagues + cups + UEFA competitions.
- Market cross-check available for 75 of 111 fixtures (Thursday UEL/UECL not yet priced).
- Results cross-check v ESPN: 379 of 380 paired matches identical; 1 discrepancy resolved via goal log.
- No absentee feed for: Manchester City v AEK Athens, Jagiellonia Białystok v RSC Anderlecht, FC Kairat Almaty v Panathinaikos FC, FC Iberia 1999 v Mjällby AIF, Inter Club d'Escaldes v Universitatea Craiova, FK Borac Banja Luka v Kuopion Palloseura, AGF v KF Egnatia.
- Backtest (n=2031): model O2.5 Brier 0.2423, market 0.2381, coherent 25/75 blend (used) 0.2384; 1X2 RPS model 0.2041, market 0.1981, used 0.1988.

## Section 2 — Complete probability matrix (final estimates)

| Kickoff (UTC) | Comp | Match | O2.5 | O3.5 | BTTS | Home | Draw | Away | xG | Min. reliability |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| Fri 16 Oct 17:00 | SuperLig | Çorum FK v Çaykur Rizespor | 56.9% | 34.5% | 59.6% | 46.1% | 25.5% | 28.4% | 1.69–1.28 | Medium |
| Fri 16 Oct 18:30 | Bundesliga | Eintracht Frankfurt v 1. FC Köln | 69.1% | 47.7% | 67.7% | 53.4% | 22.2% | 24.4% | 2.14–1.42 | Low |
| Fri 16 Oct 18:45 | SerieA | Frosinone v Sassuolo | 65.0% | 43.0% | 66.9% | 39.3% | 24.7% | 36.0% | 1.71–1.63 | Low |
| Fri 16 Oct 18:45 | Ligue1 | Le Mans v Toulouse | 55.8% | 33.4% | 59.6% | 30.1% | 26.8% | 43.1% | 1.31–1.61 | Low |
| Fri 16 Oct 19:00 | LaLiga | Deportivo de A Coruña v Levante UD | 49.2% | 27.4% | 53.8% | 43.4% | 27.1% | 29.5% | 1.47–1.17 | Low |
| Sat 17 Oct 10:30 | SuperLig | Erzurumspor FK v Eyüpspor | 45.8% | 24.4% | 45.4% | 58.9% | 25.0% | 16.1% | 1.72–0.79 | Medium |
| Sat 17 Oct 11:30 | PL | Everton v Chelsea | 56.0% | 33.6% | 59.0% | 31.6% | 25.2% | 43.2% | 1.33–1.59 | Medium |
| Sat 17 Oct 12:00 | LaLiga | Espanyol v Atlético Madrid | 52.6% | 30.4% | 53.0% | 20.3% | 24.2% | 55.5% | 0.99–1.79 | Medium |
| Sat 17 Oct 13:00 | SerieA | Venezia v SSC Napoli | 54.5% | 32.1% | 54.5% | 20.0% | 24.2% | 55.8% | 1.02–1.84 | Medium |
| Sat 17 Oct 13:00 | SuperLig | Gençlerbirliği v Galatasaray | 62.4% | 40.1% | 55.0% | 14.1% | 18.9% | 67.0% | 0.95–2.27 | Low |
| Sat 17 Oct 13:00 | SuperLig | Amed Sportif Faaliyetler v Konyaspor | 49.0% | 27.1% | 52.0% | 50.3% | 26.5% | 23.2% | 1.61–1.02 | High |
| Sat 17 Oct 13:30 | Bundesliga | 1. FC Union Berlin v Borussia Dortmund | 62.0% | 39.8% | 59.3% | 18.3% | 22.1% | 59.6% | 1.10–2.10 | Medium |
| Sat 17 Oct 13:30 | Bundesliga | Hamburger SV v VfB Stuttgart | 65.9% | 44.0% | 65.1% | 24.6% | 22.6% | 52.7% | 1.35–2.04 | Low |
| Sat 17 Oct 13:30 | Bundesliga | FC Schalke 04 v 1. FSV Mainz 05 | 58.2% | 35.8% | 60.8% | 29.7% | 25.2% | 45.1% | 1.33–1.69 | Medium |
| Sat 17 Oct 13:30 | Bundesliga | SV Werder Bremen v SC Paderborn 07 | 60.5% | 38.1% | 60.3% | 53.4% | 23.0% | 23.6% | 1.92–1.21 | Medium |
| Sat 17 Oct 13:30 | Bundesliga | SV 07 Elversberg v FC Augsburg | 64.2% | 42.1% | 66.2% | 40.2% | 24.8% | 35.0% | 1.72–1.59 | Medium |
| Sat 17 Oct 14:00 | PL | Manchester City v Ipswich Town | 67.6% | 46.0% | 52.3% | 76.3% | 14.3% | 9.4% | 2.65–0.83 | Medium |
| Sat 17 Oct 14:00 | PL | Brentford v Liverpool FC | 59.5% | 37.1% | 62.4% | 39.7% | 25.2% | 35.1% | 1.59–1.49 | Medium |
| Sat 17 Oct 14:00 | PL | Fulham v Hull City | 54.7% | 32.4% | 53.8% | 57.6% | 23.2% | 19.2% | 1.88–0.99 | High |
| Sat 17 Oct 14:15 | LaLiga | Villarreal v Elche | 62.1% | 39.9% | 57.2% | 63.3% | 20.0% | 16.7% | 2.18–1.03 | Low |
| Sat 17 Oct 15:15 | Ligue1 | RC Strasbourg v Paris Saint-Germain | 69.2% | 47.8% | 61.6% | 15.5% | 18.0% | 66.5% | 1.12–2.45 | Medium |
| Sat 17 Oct 16:00 | SerieA | Bologna v Inter | 55.5% | 33.1% | 55.1% | 19.2% | 24.1% | 56.6% | 1.02–1.88 | Low |
| Sat 17 Oct 16:00 | SuperLig | Fenerbahçe v Alanyaspor | 59.6% | 37.2% | 49.0% | 71.4% | 18.1% | 10.5% | 2.31–0.78 | Medium |
| Sat 17 Oct 16:30 | PL | Newcastle United v Aston Villa | 59.2% | 36.8% | 62.3% | 42.5% | 25.9% | 31.6% | 1.66–1.41 | Medium |
| Sat 17 Oct 16:30 | LaLiga | Real Betis v FC Barcelona | 73.9% | 53.6% | 66.8% | 17.5% | 17.5% | 64.9% | 1.29–2.56 | Low |
| Sat 17 Oct 16:30 | Bundesliga | FC Bayern München v RB Leipzig | 83.1% | 66.5% | 68.6% | 76.8% | 12.9% | 10.2% | 3.30–1.24 | Medium |
| Sat 17 Oct 18:45 | SerieA | AS Roma v Genoa | 52.0% | 29.8% | 49.6% | 61.2% | 23.1% | 15.8% | 1.90–0.86 | Low |
| Sat 17 Oct 18:45 | Ligue1 | Lille v Stade Brestois | 54.7% | 32.4% | 56.7% | 50.7% | 25.4% | 24.0% | 1.74–1.13 | Medium |
| Sat 17 Oct 18:45 | Ligue1 | Troyes v RC Lens | 59.2% | 36.8% | 60.0% | 24.8% | 23.9% | 51.3% | 1.23–1.84 | Medium |
| Sat 17 Oct 19:00 | LaLiga | Valencia v Athletic Club | 45.1% | 23.8% | 51.2% | 31.0% | 28.9% | 40.2% | 1.14–1.34 | Low |
| Sun 18 Oct 10:30 | SerieA | Udinese v Lecce | 47.3% | 25.7% | 50.4% | 51.1% | 26.8% | 22.1% | 1.60–0.97 | High |
| Sun 18 Oct 10:30 | SuperLig | Kasımpaşa v Samsunspor | 47.4% | 25.7% | 52.8% | 37.9% | 27.7% | 34.4% | 1.32–1.25 | Medium |
| Sun 18 Oct 12:00 | LaLiga | Osasuna v Real Racing Club | 59.1% | 36.7% | 60.8% | 49.6% | 25.2% | 25.3% | 1.81–1.25 | Medium |
| Sun 18 Oct 13:00 | PL | Leeds United v Manchester United | 57.6% | 35.2% | 61.0% | 41.1% | 26.1% | 32.8% | 1.59–1.40 | High |
| Sun 18 Oct 13:00 | PL | Brighton & Hove Albion v Crystal Palace | 60.2% | 37.8% | 56.8% | 61.0% | 21.2% | 17.8% | 2.08–1.04 | High |
| Sun 18 Oct 13:00 | PL | Bournemouth v Sunderland | 52.2% | 30.0% | 55.5% | 47.7% | 26.5% | 25.8% | 1.62–1.14 | Medium |
| Sun 18 Oct 13:00 | SerieA | Fiorentina v Como | 55.6% | 33.2% | 59.0% | 27.8% | 26.6% | 45.6% | 1.25–1.65 | Medium |
| Sun 18 Oct 13:00 | Ligue1 | Angers v Olympique de Marseille | 59.0% | 36.6% | 60.8% | 27.5% | 24.5% | 48.0% | 1.29–1.77 | Medium |
| Sun 18 Oct 13:00 | SuperLig | Kocaelispor v Göztepe | 49.1% | 27.2% | 54.2% | 33.9% | 27.4% | 38.7% | 1.27–1.37 | High |
| Sun 18 Oct 13:30 | Bundesliga | Bayer 04 Leverkusen v SC Freiburg | 63.8% | 41.7% | 62.1% | 56.2% | 22.1% | 21.6% | 2.06–1.22 | Medium |
| Sun 18 Oct 14:15 | LaLiga | Celta Vigo v Deportivo Alavés | 42.0% | 21.3% | 47.6% | 43.6% | 28.3% | 28.0% | 1.34–1.02 | Medium |
| Sun 18 Oct 15:15 | Ligue1 | Lorient v AS Monaco | 50.0% | 28.0% | 54.5% | 30.4% | 26.9% | 42.7% | 1.20–1.47 | Low |
| Sun 18 Oct 15:15 | Ligue1 | Paris FC v Stade Rennais | 57.1% | 34.7% | 60.3% | 42.7% | 25.7% | 31.6% | 1.61–1.36 | High |
| Sun 18 Oct 15:15 | Ligue1 | Le Havre v Auxerre | 51.4% | 29.3% | 56.2% | 40.8% | 27.6% | 31.6% | 1.47–1.26 | Medium |
| Sun 18 Oct 15:30 | PL | Nottingham Forest v Arsenal | 48.7% | 26.9% | 48.1% | 16.5% | 24.6% | 58.9% | 0.84–1.78 | High |
| Sun 18 Oct 15:30 | Bundesliga | Borussia M'gladbach v TSG Hoffenheim | 66.6% | 44.8% | 67.7% | 34.1% | 23.6% | 42.2% | 1.62–1.81 | Low |
| Sun 18 Oct 16:00 | SerieA | AC Milan v Atalanta | 54.9% | 32.5% | 56.5% | 51.4% | 25.0% | 23.6% | 1.75–1.12 | Medium |
| Sun 18 Oct 16:00 | SuperLig | Başakşehir FK v Gaziantep FK | 58.6% | 36.2% | 57.7% | 56.7% | 23.1% | 20.2% | 1.95–1.09 | High |
| Sun 18 Oct 16:30 | LaLiga | Málaga CF v Real Sociedad | 53.0% | 30.7% | 57.3% | 31.1% | 27.0% | 41.9% | 1.28–1.52 | Medium |
| Sun 18 Oct 18:45 | SerieA | Juventus v Lazio | 49.6% | 27.7% | 50.0% | 56.8% | 24.9% | 18.3% | 1.76–0.90 | High |
| Sun 18 Oct 18:45 | Ligue1 | Olympique Lyonnais v Nice | 57.5% | 35.1% | 56.3% | 57.4% | 22.9% | 19.7% | 1.94–1.06 | High |
| Sun 18 Oct 19:00 | LaLiga | Real Madrid v Sevilla | 65.9% | 44.0% | 51.4% | 75.4% | 14.6% | 10.0% | 2.57–0.82 | Low |
| Mon 19 Oct 16:30 | SerieA | Monza v Cagliari | 45.2% | 23.9% | 51.8% | 38.1% | 29.8% | 32.1% | 1.30–1.18 | Medium |
| Mon 19 Oct 17:00 | SuperLig | Trabzonspor v Beşiktaş JK | 59.2% | 36.8% | 62.1% | 32.6% | 25.5% | 41.9% | 1.43–1.64 | Low |
| Mon 19 Oct 18:45 | SerieA | Parma v Torino | 40.6% | 20.2% | 47.6% | 30.9% | 30.1% | 39.0% | 1.07–1.23 | Medium |
| Mon 19 Oct 19:00 | PL | Tottenham Hotspur v Coventry City | 58.9% | 36.5% | 55.4% | 61.8% | 21.9% | 16.2% | 2.07–0.98 | Low |
| Mon 19 Oct 19:00 | LaLiga | Getafe v Rayo Vallecano | 37.0% | 17.6% | 45.0% | 32.9% | 31.6% | 35.6% | 1.06–1.11 | High |
| Tue 20 Oct 16:45 | UCL | Sabah FK v Borussia Dortmund | 65.7% | 43.8% | 55.6% | 13.1% | 16.5% | 70.4% | 0.95–2.43 | Low |
| Tue 20 Oct 16:45 | UCL | Fenerbahçe v SK Slavia Praha | 58.6% | 36.2% | 58.2% | 55.4% | 23.4% | 21.2% | 1.92–1.12 | Medium |
| Tue 20 Oct 19:00 | UCL | Paris Saint-Germain v FC Barcelona | 76.8% | 57.5% | 75.7% | 42.9% | 21.6% | 35.4% | 2.12–1.93 | Low |
| Tue 20 Oct 19:00 | UCL | Manchester City v AEK Athens | 72.7% | 52.1% | 39.2% | 88.4% | 8.9% | 2.7% | 3.26–0.52 | Low |
| Tue 20 Oct 19:00 | UCL | Liverpool FC v Villarreal | 62.6% | 40.4% | 57.6% | 63.8% | 21.0% | 15.2% | 2.22–1.01 | High |
| Tue 20 Oct 19:00 | UCL | VfB Stuttgart v Atlético Madrid | 62.2% | 40.0% | 64.8% | 32.6% | 25.5% | 41.9% | 1.50–1.71 | High |
| Tue 20 Oct 19:00 | UCL | SSC Napoli v Bodø/Glimt | 63.4% | 41.3% | 61.8% | 56.7% | 22.6% | 20.7% | 2.07–1.20 | Low |
| Tue 20 Oct 19:00 | UCL | FC Porto v PSV Eindhoven | 60.8% | 38.4% | 59.4% | 56.2% | 22.2% | 21.5% | 1.98–1.16 | High |
| Tue 20 Oct 19:00 | UCL | AS Roma v ŠK Slovan Bratislava | 71.0% | 50.0% | 48.3% | 82.5% | 11.2% | 6.3% | 2.95–0.72 | Medium |
| Wed 21 Oct 16:45 | UCL | Como v Manchester United | 57.1% | 34.7% | 60.5% | 38.9% | 25.7% | 35.4% | 1.53–1.45 | Medium |
| Wed 21 Oct 16:45 | UCL | Lille v Galatasaray | 56.8% | 34.4% | 59.9% | 45.1% | 26.0% | 28.8% | 1.66–1.29 | Medium |
| Wed 21 Oct 19:00 | UCL | Real Madrid v RB Leipzig | 74.7% | 54.7% | 62.5% | 73.0% | 16.0% | 11.0% | 2.83–1.07 | Medium |
| Wed 21 Oct 19:00 | UCL | FC Bayern München v Arsenal | 59.5% | 37.1% | 62.6% | 42.3% | 25.9% | 31.7% | 1.66–1.42 | Medium |
| Wed 21 Oct 19:00 | UCL | Inter v Shakhtar Donetsk | 69.7% | 48.5% | 54.2% | 76.5% | 14.4% | 9.1% | 2.74–0.86 | Low |
| Wed 21 Oct 19:00 | UCL | Aston Villa v Viking FK | 71.0% | 50.0% | 57.6% | 74.4% | 16.0% | 9.6% | 2.74–0.94 | Medium |
| Wed 21 Oct 19:00 | UCL | Real Betis v Feyenoord | 66.8% | 45.0% | 62.9% | 60.0% | 20.2% | 19.8% | 2.22–1.22 | Medium |
| Wed 21 Oct 19:00 | UCL | Sporting CP v LASK | 69.0% | 47.5% | 54.8% | 75.1% | 14.8% | 10.1% | 2.67–0.89 | Medium |
| Wed 21 Oct 19:00 | UCL | Club Brugge KV v RC Lens | 62.7% | 40.5% | 63.2% | 47.7% | 22.6% | 29.8% | 1.83–1.40 | Low |
| Thu 22 Oct 14:30 | UECL | FC Kairat Almaty v Panathinaikos FC | 45.0% | 23.7% | 47.7% | 21.0% | 26.5% | 52.5% | 0.90–1.57 | Medium |
| Thu 22 Oct 16:45 | UEL | Juventus v Stade Rennais | 59.9% | 37.5% | 56.6% | 60.9% | 21.6% | 17.5% | 2.07–1.03 | Medium |
| Thu 22 Oct 16:45 | UEL | OFI Crete v Bayer 04 Leverkusen | 57.6% | 35.2% | 48.7% | 11.3% | 19.0% | 69.7% | 0.78–2.22 | Medium |
| Thu 22 Oct 16:45 | UEL | SK Sturm Graz v Olympique de Marseille | 61.0% | 38.6% | 61.4% | 25.1% | 23.5% | 51.4% | 1.27–1.88 | Medium |
| Thu 22 Oct 16:45 | UEL | Lech Poznań v Sunderland | 58.1% | 35.7% | 60.4% | 29.0% | 24.8% | 46.2% | 1.31–1.71 | Medium |
| Thu 22 Oct 16:45 | UEL | GNK Dinamo Zagreb v NEC Nijmegen | 65.5% | 43.6% | 65.4% | 50.2% | 22.8% | 27.0% | 1.97–1.41 | Medium |
| Thu 22 Oct 16:45 | UEL | Royale Union Saint-Gilloise v Hapoel Be'er Sheva | 55.4% | 33.0% | 49.5% | 66.0% | 20.7% | 13.3% | 2.08–0.82 | Low |
| Thu 22 Oct 16:45 | UEL | FC Ararat-Armenia v AZ Alkmaar | 66.2% | 44.4% | 57.6% | 13.2% | 18.2% | 68.6% | 0.99–2.42 | Medium |
| Thu 22 Oct 16:45 | UEL | Ferencváros TC v Torreense | 54.9% | 32.5% | 50.6% | 63.7% | 21.6% | 14.7% | 2.01–0.86 | Low |
| Thu 22 Oct 16:45 | UECL | FK Jablonec v Brighton & Hove Albion | 61.1% | 38.8% | 46.5% | 8.3% | 16.2% | 75.6% | 0.70–2.46 | Medium |
| Thu 22 Oct 16:45 | UECL | FK Crvena zvezda v FC København | 64.9% | 42.9% | 66.4% | 35.9% | 23.8% | 40.3% | 1.62–1.72 | Medium |
| Thu 22 Oct 16:45 | UECL | Trabzonspor v Heart of Midlothian | 54.3% | 31.9% | 54.8% | 54.5% | 24.2% | 21.3% | 1.80–1.05 | Medium |
| Thu 22 Oct 16:45 | UECL | Getafe v FC Lugano | 42.6% | 21.8% | 47.9% | 45.7% | 28.3% | 26.0% | 1.40–0.99 | Medium |
| Thu 22 Oct 16:45 | UECL | Pafos FC v Riga FC | 56.4% | 34.0% | 54.3% | 59.5% | 22.6% | 17.9% | 1.96–0.98 | Medium |
| Thu 22 Oct 16:45 | UECL | FC Nordsjælland v CSKA Sofia | 61.9% | 39.6% | 55.8% | 65.3% | 19.9% | 14.8% | 2.22–0.97 | Medium |
| Thu 22 Oct 16:45 | UECL | FK Kauno Žalgiris v SK Brann | 60.4% | 38.0% | 55.9% | 16.1% | 20.9% | 63.1% | 0.99–2.13 | Medium |
| Thu 22 Oct 16:45 | UECL | FC Iberia 1999 v Mjällby AIF | 52.3% | 30.1% | 50.4% | 16.8% | 23.1% | 60.1% | 0.89–1.88 | Medium |
| Thu 22 Oct 16:45 | UECL | Inter Club d'Escaldes v Universitatea Craiova | 49.9% | 27.9% | 50.6% | 19.7% | 24.8% | 55.5% | 0.94–1.73 | Low |
| Thu 22 Oct 19:00 | UEL | Bournemouth v AC Milan | 57.5% | 35.0% | 56.8% | 56.2% | 23.2% | 20.6% | 1.91–1.08 | Medium |
| Thu 22 Oct 19:00 | UEL | Omonia Nicosia v Benfica | 55.1% | 32.8% | 54.7% | 20.0% | 23.5% | 56.5% | 1.02–1.86 | Medium |
| Thu 22 Oct 19:00 | UEL | Beşiktaş JK v Crystal Palace | 52.8% | 30.5% | 54.7% | 23.7% | 25.2% | 51.1% | 1.09–1.70 | Medium |
| Thu 22 Oct 19:00 | UEL | Celtic v Celta Vigo | 47.3% | 25.7% | 52.7% | 32.8% | 27.8% | 39.5% | 1.21–1.35 | Medium |
| Thu 22 Oct 19:00 | UEL | TSG Hoffenheim v Olympique Lyonnais | 56.0% | 33.6% | 58.8% | 29.4% | 25.4% | 45.3% | 1.28–1.64 | Medium |
| Thu 22 Oct 19:00 | UEL | Lillestrøm SK v Real Sociedad | 56.3% | 33.9% | 58.8% | 28.3% | 25.1% | 46.6% | 1.26–1.68 | Medium |
| Thu 22 Oct 19:00 | UEL | Olympiacos FC v AC Sparta Praha | 47.1% | 25.5% | 46.3% | 59.4% | 24.3% | 16.3% | 1.75–0.81 | Medium |
| Thu 22 Oct 19:00 | UEL | NK Celje v Red Bull Salzburg | 62.7% | 40.5% | 64.0% | 29.8% | 23.9% | 46.3% | 1.42–1.81 | Medium |
| Thu 22 Oct 19:00 | UEL | Jagiellonia Białystok v RSC Anderlecht | 54.1% | 31.8% | 58.0% | 32.8% | 26.1% | 41.2% | 1.33–1.52 | Medium |
| Thu 22 Oct 19:00 | UEL | FC Viktoria Plzeň v Levski Sofia | 49.3% | 27.4% | 53.1% | 46.7% | 26.6% | 26.7% | 1.54–1.10 | Medium |
| Thu 22 Oct 19:00 | UECL | AFC Ajax v Atalanta | 64.0% | 41.9% | 65.6% | 35.1% | 24.0% | 40.9% | 1.58–1.72 | Medium |
| Thu 22 Oct 19:00 | UECL | AS Monaco v SC Freiburg | 58.5% | 36.1% | 60.6% | 46.8% | 24.7% | 28.6% | 1.73–1.31 | Medium |
| Thu 22 Oct 19:00 | UECL | Sporting Braga v KAA Gent | 42.8% | 22.0% | 44.3% | 56.0% | 26.1% | 17.9% | 1.60–0.79 | Medium |
| Thu 22 Oct 19:00 | UECL | FC Midtjylland v Sint-Truidense VV | 61.2% | 38.9% | 59.0% | 58.5% | 22.0% | 19.5% | 2.05–1.11 | Medium |
| Thu 22 Oct 19:00 | UECL | FC Thun v HNK Hajduk Split | 61.2% | 38.9% | 63.5% | 40.0% | 24.6% | 35.4% | 1.63–1.53 | Medium |
| Thu 22 Oct 19:00 | UECL | Lincoln Red Imps v FC Twente | 69.6% | 48.3% | 51.7% | 7.6% | 13.8% | 78.6% | 0.79–2.80 | Low |
| Thu 22 Oct 19:00 | UECL | FK Borac Banja Luka v Kuopion Palloseura | 51.1% | 29.0% | 54.8% | 46.0% | 26.3% | 27.7% | 1.56–1.16 | Medium |
| Thu 22 Oct 19:00 | UECL | AGF v KF Egnatia | 58.1% | 35.6% | 54.4% | 62.1% | 21.5% | 16.4% | 2.05–0.96 | Low |

## Section 8 — Overall master ranking (top 40 by final probability)

| # | Fixture | Outcome | Estimate | Model | Market | Reliability | Correlated with |
|---:|---|---|---:|---:|---:|---|---|
| 1 | Manchester City v AEK Athens | Home Win | 88.4% | 77.3% | 90.0% | Low |  |
| 2 | FC Bayern München v RB Leipzig | Over 2.5 | 83.1% | 78.9% | 82.8% | High |  |
| 3 | AS Roma v ŠK Slovan Bratislava | Home Win | 82.5% | 80.8% | 81.8% | High |  |
| 4 | Lincoln Red Imps v FC Twente | Away Win | 78.6% | 78.6% | – | Low |  |
| 5 | FC Bayern München v RB Leipzig | Home Win | 76.8% | 74.0% | 77.5% | High | #2 |
| 6 | Paris Saint-Germain v FC Barcelona | Over 2.5 | 76.8% | 71.4% | 78.0% | Medium |  |
| 7 | Inter v Shakhtar Donetsk | Home Win | 76.5% | 69.5% | 78.1% | Medium |  |
| 8 | Manchester City v Ipswich Town | Home Win | 76.3% | 73.3% | 76.7% | High |  |
| 9 | Paris Saint-Germain v FC Barcelona | BTTS Yes | 75.7% | 70.6% | 75.0% | High | #6 |
| 10 | FK Jablonec v Brighton & Hove Albion | Away Win | 75.6% | 75.6% | – | Medium |  |
| 11 | Real Madrid v Sevilla | Home Win | 75.4% | 71.5% | 76.3% | High |  |
| 12 | Sporting CP v LASK | Home Win | 75.1% | 74.5% | 74.2% | High |  |
| 13 | Real Madrid v RB Leipzig | Over 2.5 | 74.7% | 71.4% | 76.2% | High |  |
| 14 | Aston Villa v Viking FK | Home Win | 74.4% | 68.2% | 75.6% | Medium |  |
| 15 | Real Betis v FC Barcelona | Over 2.5 | 73.9% | 67.4% | 76.2% | Medium |  |
| 16 | Real Madrid v RB Leipzig | Home Win | 73.0% | 66.7% | 74.3% | Medium | #13 |
| 17 | Manchester City v AEK Athens | Over 2.5 | 72.7% | 62.9% | 76.2% | Low | #1 |
| 18 | Fenerbahçe v Alanyaspor | Home Win | 71.4% | 68.3% | 71.6% | High |  |
| 19 | Aston Villa v Viking FK | Over 2.5 | 71.0% | 67.7% | 71.8% | High | #14 |
| 20 | AS Roma v ŠK Slovan Bratislava | Over 2.5 | 71.0% | 66.3% | 72.9% | Medium | #3 |
| 21 | Sabah FK v Borussia Dortmund | Away Win | 70.4% | 59.3% | 72.7% | Low |  |
| 22 | Inter v Shakhtar Donetsk | Over 2.5 | 69.7% | 62.3% | 71.8% | Medium | #7 |
| 23 | OFI Crete v Bayer 04 Leverkusen | Away Win | 69.7% | 69.7% | – | Medium |  |
| 24 | Lincoln Red Imps v FC Twente | Over 2.5 | 69.6% | 69.6% | – | Low | #4 |
| 25 | RC Strasbourg v Paris Saint-Germain | Over 2.5 | 69.2% | 62.9% | 71.8% | Medium |  |
| 26 | Eintracht Frankfurt v 1. FC Köln | Over 2.5 | 69.1% | 60.1% | 71.8% | Low |  |
| 27 | Sporting CP v LASK | Over 2.5 | 69.0% | 63.7% | 71.8% | Medium | #12 |
| 28 | FC Bayern München v RB Leipzig | BTTS Yes | 68.6% | 66.1% | 68.8% | High | #2 |
| 29 | FC Ararat-Armenia v AZ Alkmaar | Away Win | 68.6% | 68.6% | – | Medium |  |
| 30 | Eintracht Frankfurt v 1. FC Köln | BTTS Yes | 67.7% | 59.0% | 68.8% | Medium | #26 |
| 31 | Borussia M'gladbach v TSG Hoffenheim | BTTS Yes | 67.7% | 62.9% | 68.8% | Medium |  |
| 32 | Manchester City v Ipswich Town | Over 2.5 | 67.6% | 63.2% | 70.1% | Medium | #8 |
| 33 | Gençlerbirliği v Galatasaray | Away Win | 67.0% | 56.6% | 70.9% | Low |  |
| 34 | Frosinone v Sassuolo | BTTS Yes | 66.9% | 58.8% | 68.8% | Medium |  |
| 35 | Real Betis v FC Barcelona | BTTS Yes | 66.8% | 65.4% | 66.3% | High | #15 |
| 36 | Real Betis v Feyenoord | Over 2.5 | 66.8% | 62.2% | 68.2% | Medium |  |
| 37 | Borussia M'gladbach v TSG Hoffenheim | Over 2.5 | 66.6% | 61.0% | 68.2% | Medium | #31 |
| 38 | RC Strasbourg v Paris Saint-Germain | Away Win | 66.5% | 62.8% | 67.6% | High | #25 |
| 39 | FC Bayern München v RB Leipzig | Over 3.5 | 66.5% | 60.3% | 70.1% | Medium | #2 |
| 40 | FK Crvena zvezda v FC København | BTTS Yes | 66.4% | 66.4% | – | Medium |  |

Probabilities are estimates for 90 minutes plus stoppage time, not guarantees. Selections from the same fixture are correlated.
