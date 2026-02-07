import sys
import random
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QLabel, QPushButton, QTextEdit,
    QTabWidget, QProgressBar, QInputDialog
)
from PyQt5.QtCore import Qt, QTimer
from PyQt5.QtGui import QFont

# =========================
# Utilities
# =========================
def format_number(n):
    return "{:,}".format(n)

def clamp(n, smallest, largest):
    return max(smallest, min(n, largest))

# =========================
# Enforcers, Associates, Bots, Turfs, Player
# =========================
enforcer_types = {
    "Bikers": ["Bubba","Captain","Cee-Jay","Fang","Jade","The Professor","Lupo Solitario","Mirror","Ouka","Red Thorn","Sicario","Snowstorm","Tony","Vinny"],
    "Bruisers": ["Bone Crusher","Deathlok","El Cazador","El Cortador","El Santo","Hellcat","Killer Queen","Lucky","Maestro","Medusa","Mike","Nihilista","Onryo","The Count","Titan","T-Roc"],
    "Hitmen": ["@anonymous","Belladonna","Big Shot","Blade Shadow","Brutus","Huntress","Mickey","Nioh","Papi","Paulie","Sparrow","Tengu","White Dove","Mortar Car","Doxxy","Kitsune","Mantis","The Tsar"]
}

class Enforcer:
    def __init__(self, name, type_, tier):
        self.name = name
        self.type = type_
        self.tier = tier
        self.bonus_troops = {1:10000,2:20000,3:50000,4:100000}[tier]
        self.buff_percent = {1:0.05,2:0.1,3:0.15,4:0.25}[tier]

class Associate:
    def __init__(self, name, tier):
        self.name = name
        self.tier = tier
        self.buff_percent = {1:0.05,2:0.1,3:0.15,4:0.25}[tier]

class Bot:
    def __init__(self, name):
        self.name = name
        self.troops = 256_000

class Turf:
    def __init__(self, name):
        self.name = name
        self.troops = random.randint(500_000, 2_000_000)
        self.max_troops = self.troops
        self.enforcers = self.generate_enforcers()
    def generate_enforcers(self):
        enforcers = []
        for _ in range(random.randint(1,3)):
            type_ = random.choice(list(enforcer_types.keys()))
            name = random.choice(enforcer_types[type_])
            tier = random.randint(1,4)
            enforcers.append(Enforcer(name,type_,tier))
        return enforcers

class Player:
    def __init__(self,name):
        self.name = name
        self.base_troops = 1_000_000
        self.max_troops = 256_000
        self.crew_atk = 100
        self.crew_def = 100
        self.crew_hp = 100
        self.hitman_atk = 50
        self.hitman_def = 50
        self.hitman_hp = 50
        self.enforcers = []
        self.associates = []
        self.turfs_owned = []
        self.faction = None
        self.training_center_level = 1
        self.investment_center_level = 1
        self.hospital = 0
        self.sanitarium = 0
    def get_max_send_troops(self,buff_percent=0):
        bonus = sum(e.bonus_troops for e in self.enforcers)
        troops = self.max_troops + bonus
        troops = int(troops * (1 + buff_percent))
        return min(troops, 2_270_000)

# =========================
# Main GUI
# =========================
class MafiaGUI(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Grand Mafia Advanced")
        self.setGeometry(50,50,1300,850)
        self.setStyleSheet("background-color:#1a1a1a; color:white;")
        self.turfs = [Turf(f"Turf {i}") for i in range(1,6)]
        self.bots = [Bot(f"Bot {i+1}") for i in range(10)]
        self.initUI()

    def initUI(self):
        layout = QVBoxLayout()
        title = QLabel("Grand Mafia Advanced GUI")
        title.setFont(QFont("Arial",24,QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("color:purple;")
        layout.addWidget(title)

        self.player_name, ok = QInputDialog.getText(self,"Player Name","Enter your name:")
        if not ok or not self.player_name:
            self.player_name = "Player1"
        self.player = Player(self.player_name)

        # Tabs
        self.tabs = QTabWidget()
        self.tabs.setStyleSheet(
            "QTabBar::tab {background:black; color:white; padding:10px;} QTabBar::tab:selected {background:purple;}"
        )

        # Dashboard Tab
        self.dashboard_tab = QWidget()
        self.dashboard_layout = QVBoxLayout()

        self.troop_bar = QProgressBar()
        self.troop_bar.setStyleSheet(
            "QProgressBar {border:2px solid purple; text-align:center;} QProgressBar::chunk {background-color:purple;}"
        )
        self.influence_bar = QProgressBar()
        self.influence_bar.setStyleSheet(
            "QProgressBar {border:2px solid purple; text-align:center;} QProgressBar::chunk {background-color:purple;}"
        )
        self.hospital_bar = QProgressBar()
        self.hospital_bar.setStyleSheet(
            "QProgressBar {border:2px solid green; text-align:center;} QProgressBar::chunk {background-color:green;}"
        )
        self.sanitarium_bar = QProgressBar()
        self.sanitarium_bar.setStyleSheet(
            "QProgressBar {border:2px solid orange; text-align:center;} QProgressBar::chunk {background-color:orange;}"
        )

        self.dashboard_layout.addWidget(QLabel("Troops"))
        self.dashboard_layout.addWidget(self.troop_bar)
        self.dashboard_layout.addWidget(QLabel("Influence Buff"))
        self.dashboard_layout.addWidget(self.influence_bar)
        self.dashboard_layout.addWidget(QLabel("Hospital"))
        self.dashboard_layout.addWidget(self.hospital_bar)
        self.dashboard_layout.addWidget(QLabel("Sanitarium"))
        self.dashboard_layout.addWidget(self.sanitarium_bar)

        heal_btn = QPushButton("Heal from Hospital")
        heal_btn.setStyleSheet("border:2px solid green; color:white;")
        heal_btn.clicked.connect(self.heal_hospital)
        self.dashboard_layout.addWidget(heal_btn)
        self.dashboard_tab.setLayout(self.dashboard_layout)

        # Turfs Tab
        self.turfs_tab = QWidget()
        self.turfs_layout = QVBoxLayout()
        self.turf_text = QTextEdit()
        self.turf_text.setReadOnly(True)
        self.turf_text.setStyleSheet("background-color:#1e1e1e; color:white;")
        self.turfs_layout.addWidget(self.turf_text)
        self.turfs_tab.setLayout(self.turfs_layout)

        view_turfs_btn = QPushButton("Refresh Turfs")
        view_turfs_btn.setStyleSheet("border:2px solid purple;")
        view_turfs_btn.clicked.connect(self.view_turfs)
        self.turfs_layout.addWidget(view_turfs_btn)

        attack_btn = QPushButton("Attack/Raid Turf")
        attack_btn.setStyleSheet("border:2px solid red;")
        attack_btn.clicked.connect(self.select_attack)
        self.turfs_layout.addWidget(attack_btn)

        # Faction Tab
        self.faction_tab = QWidget()
        self.faction_layout = QVBoxLayout()
        faction_btn = QPushButton("Create Faction")
        faction_btn.setStyleSheet("border:2px solid purple;")
        faction_btn.clicked.connect(self.create_faction)
        self.faction_layout.addWidget(faction_btn)

        assoc_btn = QPushButton("Train Associate")
        assoc_btn.setStyleSheet("border:2px solid purple;")
        assoc_btn.clicked.connect(self.train_associate)
        self.faction_layout.addWidget(assoc_btn)
        self.faction_tab.setLayout(self.faction_layout)

        # Buildings Tab
        self.buildings_tab = QWidget()
        self.buildings_layout = QVBoxLayout()
        training_btn = QPushButton("Upgrade Training Center")
        training_btn.setStyleSheet("border:2px solid purple;")
        training_btn.clicked.connect(self.upgrade_training)
        self.buildings_layout.addWidget(training_btn)
        invest_btn = QPushButton("Upgrade Investment Center")
        invest_btn.setStyleSheet("border:2px solid purple;")
        invest_btn.clicked.connect(self.upgrade_investment)
        self.buildings_layout.addWidget(invest_btn)
        self.buildings_tab.setLayout(self.buildings_layout)

        # Battle Report Tab
        self.battle_tab = QWidget()
        self.battle_layout = QVBoxLayout()
        self.battle_text = QTextEdit()
        self.battle_text.setReadOnly(True)
        self.battle_text.setStyleSheet("background-color:#1e1e1e; color:white;")
        self.battle_layout.addWidget(self.battle_text)
        self.battle_tab.setLayout(self.battle_layout)

        # Add tabs
        self.tabs.addTab(self.dashboard_tab,"Dashboard")
        self.tabs.addTab(self.turfs_tab,"Turfs")
        self.tabs.addTab(self.faction_tab,"Faction/Associates")
        self.tabs.addTab(self.buildings_tab,"Buildings")
        self.tabs.addTab(self.battle_tab,"Battle Report")
        layout.addWidget(self.tabs)
        self.setLayout(layout)

        # Initialize bars
        self.update_bars()

        # Timer for sanitarium
        self.timer = QTimer()
        self.timer.timeout.connect(self.heal_sanitarium)
        self.timer.start(1000)

    # -------------------------
    # Bars Update
    # -------------------------
    def update_bars(self):
        self.troop_bar.setMaximum(2_270_000)
        self.troop_bar.setValue(self.player.base_troops)
        self.troop_bar.setFormat(f"{format_number(self.player.base_troops)} / 2,270,000")

        influence = clamp(int(sum(a.buff_percent for a in self.player.associates)*100),0,100)
        self.influence_bar.setMaximum(100)
        self.influence_bar.setValue(influence)
        self.influence_bar.setFormat(f"{influence}%")

        self.hospital_bar.setMaximum(600_000)
        self.hospital_bar.setValue(self.player.hospital)
        self.hospital_bar.setFormat(f"{format_number(self.player.hospital)} / 600,000")

        self.sanitarium_bar.setMaximum(1_000_000)
        self.sanitarium_bar.setValue(self.player.sanitarium)
        self.sanitarium_bar.setFormat(f"{format_number(self.player.sanitarium)} healing...")

    # -------------------------
    # Turf Management
    # -------------------------
    def view_turfs(self):
        self.turf_text.clear()
        for t in self.turfs:
            self.turf_text.append(f"<b style='color:purple'>{t.name}</b>")
            self.turf_text.append(f"Troops: {format_number(t.troops)} / {format_number(t.max_troops)}")
            for e in t.enforcers:
                self.turf_text.append(f"{e.name} ({e.type} T{e.tier}) Buff: {int(e.buff_percent*100)}% Bonus Troops: {format_number(e.bonus_troops)}")
            self.turf_text.append("")

    # -------------------------
    # Faction
    # -------------------------
    def create_faction(self):
        name, ok = QInputDialog.getText(self,"Faction Name","Enter Faction Name:")
        if ok and name:
            self.player.faction = name
            self.battle_text.append(f"<b>Faction <span style='color:purple'>{name}</span> created!</b>")

    # -------------------------
    # Training/Investment
    # -------------------------
    def upgrade_training(self):
        if self.player.training_center_level<25:
            self.player.training_center_level+=1
            self.battle_text.append(f"<b>Training Center upgraded to Lv {self.player.training_center_level}</b>")
        else:
            self.battle_text.append("Training Center already max level")
        self.update_bars()
    def upgrade_investment(self):
        if self.player.investment_center_level<25:
            self.player.investment_center_level+=1
            self.battle_text.append(f"<b>Investment Center upgraded to Lv {self.player.investment_center_level}</b>")
        else:
            self.battle_text.append("Investment Center already max level")
        self.update_bars()
    def train_associate(self):
        if len(self.player.associates)>=self.player.training_center_level*5:
            self.battle_text.append("Training Center full!")
            return
        name, ok = QInputDialog.getText(self,"Associate Name","Enter Associate Name:")
        if ok and name:
            max_tier = clamp(self.player.investment_center_level//5 +1,1,4)
            tier = random.randint(1,max_tier)
            self.player.associates.append(Associate(name,tier))
            self.battle_text.append(f"Trained Associate <span style='color:purple'>{name}</span> (T{tier})")
            self.update_bars()

    # -------------------------
    # Attack
    # -------------------------
    def select_attack(self):
        options = ["Solo Attack","Raid with Bots"]
        choice, ok = QInputDialog.getItem(self,"Attack Type","Choose:",options,editable=False)
        if not ok: return
        solo = choice=="Solo Attack"
        self.attack_turf(solo)

    def attack_turf(self, solo=True):
        turf_names = [t.name for t in self.turfs]
        turf_name, ok = QInputDialog.getItem(self,"Select Turf","Choose Turf:",turf_names,editable=False)
        if not ok: return
        turf = next(t for t in self.turfs if t.name==turf_name)

        buff, ok = QInputDialog.getInt(self,"Buff %","Enter buff % (0,20,50):",0,0,50)
        if not ok: buff=0
        buff/=100

        max_troops = self.player.get_max_send_troops(buff)
        troops, ok = QInputDialog.getInt(self,"Troops","Enter troops to send:",0,max_troops)
        if not ok: return

        bots = []
        if not solo:
            max_bots = min(29,len(self.bots))
            num_bots, ok = QInputDialog.getInt(self,"Bots","Number of bots to join:",0,max_bots)
            if ok: bots=self.bots[:num_bots]

        assoc_choice = QInputDialog.getItem(self,"Associate","Send an associate?",["None"]+[a.name for a in self.player.associates],editable=False)
        assoc_buff=0
        if assoc_choice[1] and assoc_choice[0]!="None":
            assoc = next(a for a in self.player.associates if a.name==assoc_choice[0])
            assoc_buff=assoc.buff_percent

        effective_troops = troops + sum(b.troops for b in bots)
        effective_troops=int(effective_troops*(1+buff+assoc_buff))
        effective_troops=clamp(effective_troops,0,2_270_000)

        defender_troops = turf.troops
        defense_multiplier=1.0
        for e in turf.enforcers:
            if e.type=="Bruisers":
                defense_multiplier+=0.05*e.tier
            elif e.type=="Hitmen":
                defense_multiplier+=0.04*e.tier
            elif e.type=="Bikers":
                defense_multiplier+=0.03*e.tier
        adjusted_defender=int(defender_troops*defense_multiplier)

        player_dead = int(effective_troops*0.05)
        player_wounded = int(effective_troops*0.1)
        enemy_dead = int(adjusted_defender*0.05)
        enemy_wounded = int(adjusted_defender*0.1)

        if effective_troops>=adjusted_defender:
            result="WIN"
            turf.troops=max(defender_troops-effective_troops,0)
            if turf.name not in self.player.turfs_owned:
                self.player.turfs_owned.append(turf.name)
        else:
            result="LOSE"
            turf.troops=max(defender_troops-int(effective_troops*0.5),0)

        total_wounded = player_wounded
        if self.player.hospital + total_wounded <= 600_000:
            self.player.hospital += total_wounded
        else:
            overflow = self.player.hospital + total_wounded - 600_000
            self.player.hospital = 600_000
            self.player.sanitarium += overflow
        self.player.base_troops -= player_dead

        self.battle_text.append(f"<b>--- Battle Report vs {turf.name} ---</b>")
        self.battle_text.append(f"Result: <span style='color:purple'>{result}</span>")
        self.battle_text.append(f"Player troops sent: {format_number(effective_troops)} | Dead: {format_number(player_dead)} | Wounded: {format_number(player_wounded)} | Remaining: {format_number(self.player.base_troops)}")
        self.battle_text.append(f"Enemy troops remaining: {format_number(turf.troops)} | Dead: {format_number(enemy_dead)} | Wounded: {format_number(enemy_wounded)}\n")

        self.update_bars()
        self.tabs.setCurrentWidget(self.battle_tab)

    # -------------------------
    # Healing
    # -------------------------
    def heal_sanitarium(self):
        if self.player.sanitarium>0 and self.player.hospital<600_000:
            self.player.sanitarium-=1
            self.player.hospital+=1
            self.update_bars()
    def heal_hospital(self):
        heal_amount = min(self._
