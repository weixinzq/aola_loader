package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.miraclepet.IMiraclePetDataService;
   import mmo.interfaces.miraclepet.MiraclePetBreakData;
   import mmo.interfaces.miraclepet.MiraclePetInfo;
   import mmo.interfaces.pet.data.PetCharacterMap;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.petcommon.GeniusHelper;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.operation.Ability;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.pet.ui.IPetUIService;
   import mmo.interfaces.petcorps.IPetCorpsService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petpackage.config.PetPackageConfig;
   import mmo.play.activity.helper.Pet_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActTipsMcHelper;
   import mmo.play.actthings.obj.ActArrHelper;
   import mmo.play.scene.FaceDirectionTypes;
   import mmo.play.scene.SceneExtInfo;
   import mmo.play.scene.SceneManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2045")]
   public class PetDetailAbility extends PetDetailBase
   {
      
      private static const START_POS:Point = new Point(668,200);
      
      private static const OFFSET:Number = 28;
      
      private static const GENIUS_POINT:Point = new Point(740,173);
      
      private static const defaultData:Array = [0,0,0,0,0,0];
      
      public var btngtips:SimpleButton;
      
      public var btnhowgenius:SimpleButton;
      
      public var btnhowstudy:SimpleButton;
      
      public var c:MovieClip;
      
      public var cTips_影响每一个回合中亚比得出手顺序:MovieClip;
      
      public var cTips_提升亚比的体力值上限:MovieClip;
      
      public var cTips_提升普通攻击类型的技能伤害:MovieClip;
      
      public var cTips_提升特殊攻击类型的技能伤害:MovieClip;
      
      public var cTips_降低受到普通攻击技能的伤害:MovieClip;
      
      public var cTips_降低受到特殊攻击技能的伤害:MovieClip;
      
      public var eff0:MovieClip;
      
      public var eff1:MovieClip;
      
      public var eff2:MovieClip;
      
      public var eff3:MovieClip;
      
      public var eff4:MovieClip;
      
      public var eff5:MovieClip;
      
      public var mcGQAbility:MovieClip;
      
      public var mcSpecialAttContent_0:MovieClip;
      
      public var mcSpecialAttTarget_0:MovieClip;
      
      public var mcSpecialName:MovieClip;
      
      public var mcbasetips:MovieClip;
      
      public var mcd:MovieClip;
      
      public var mcgeniusname:MovieClip;
      
      public var mcgtips:MovieClip;
      
      public var mcotherattacktips:MovieClip;
      
      public var mcotherdefencetips:MovieClip;
      
      public var mcotherhptips:MovieClip;
      
      public var mcothersattacktips:MovieClip;
      
      public var mcothersdefencetips:MovieClip;
      
      public var mcotherspeedtips:MovieClip;
      
      public var mcothertips:MovieClip;
      
      public var see0:MovieClip;
      
      public var see1:MovieClip;
      
      public var see2:MovieClip;
      
      public var txt_aattack:TextField;
      
      public var txt_adefence:TextField;
      
      public var txt_ahp:TextField;
      
      public var txt_asattack:TextField;
      
      public var txt_asdefence:TextField;
      
      public var txt_aspeed:TextField;
      
      public var txt_attack:TextField;
      
      public var txt_battack:TextField;
      
      public var txt_bdefence:TextField;
      
      public var txt_bhp:TextField;
      
      public var txt_bsattack:TextField;
      
      public var txt_bsdefence:TextField;
      
      public var txt_bspeed:TextField;
      
      public var txt_character:TextField;
      
      public var txt_defence:TextField;
      
      public var txt_eattack:TextField;
      
      public var txt_edefence:TextField;
      
      public var txt_ehp:TextField;
      
      public var txt_esattack:TextField;
      
      public var txt_esdefence:TextField;
      
      public var txt_espeed:TextField;
      
      public var txt_gattack:TextField;
      
      public var txt_gdefence:TextField;
      
      public var txt_ghp:TextField;
      
      public var txt_gsattack:TextField;
      
      public var txt_gsdefence:TextField;
      
      public var txt_gspeed:TextField;
      
      public var txt_hp:TextField;
      
      public var txt_lattack:TextField;
      
      public var txt_ldefence:TextField;
      
      public var txt_lhp:TextField;
      
      public var txt_lsattack:TextField;
      
      public var txt_lsdefence:TextField;
      
      public var txt_lspeed:TextField;
      
      public var txt_sattack:TextField;
      
      public var txt_sdefence:TextField;
      
      public var txt_speed:TextField;
      
      public var txt_toattack:TextField;
      
      public var txt_todefence:TextField;
      
      public var txt_tohp:TextField;
      
      public var txt_tosattack:TextField;
      
      public var txt_tosdefence:TextField;
      
      public var txt_tospeed:TextField;
      
      public var txt_xattack:TextField;
      
      public var txt_xdefence:TextField;
      
      public var txt_xhp:TextField;
      
      public var txt_xsattack:TextField;
      
      public var txt_xsdefence:TextField;
      
      public var txt_xspeed:TextField;
      
      public var txtlevel:TextField;
      
      public var txtstudy:TextField;
      
      private var txtCharacter:TextField = null;
      
      private var allContainer:Sprite;
      
      private var mcGenius:MovieClip = null;
      
      private var txtTotalAttributes:Array = null;
      
      private var mcEffs:Array = null;
      
      private var txtEffs:Array = null;
      
      private var indStars:Array = [];
      
      private var txtGenius:Array = null;
      
      private var mcDefaultInd:MovieClip;
      
      private var unseenAry:Array;
      
      private var canSeeAry:Array;
      
      private var mcGTips:MovieClip;
      
      private var btnGTips:SimpleButton;
      
      private var petUIService:IPetUIService = null;
      
      private var pmService:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var petCorpsSvr:IPetCorpsService = ServiceContainer.getService(IPetCorpsService) as IPetCorpsService;
      
      private const _gqAbilityDescArr:Array = ["提升亚比技能造成伤害时暴击触发几率（越高越好）","提高亚比造成暴击伤害时伤害的大小（越高越好）","降低亚比受到伤害时被暴击的几率（与目标暴击几率相减）","降低亚比受到暴击伤害时的伤害值"];
      
      public function PetDetailAbility()
      {
         super();
         this.initPars();
         this.initFuns();
         this.reset();
      }
      
      private function initPars() : void
      {
         this.gotoAndStop(1);
         this.txtCharacter = this.txt_character as TextField;
         this.txtTotalAttributes = [this.txt_hp,this.txt_attack,this.txt_defence,this.txt_sattack,this.txt_sdefence,this.txt_speed];
         this.mcEffs = [this.eff0,this.eff1,this.eff2,this.eff3,this.eff4,this.eff5];
         this.txtEffs = [this.txt_lhp,this.txt_lattack,this.txt_ldefence,this.txt_lsattack,this.txt_lsdefence,this.txt_lspeed];
         this.txtGenius = [this.txt_ghp,this.txt_gattack,this.txt_gdefence,this.txt_gsattack,this.txt_gsdefence,this.txt_gspeed];
         this.mcDefaultInd = this.mcd as MovieClip;
         this.unseenAry = [this.txtGenius];
         this.canSeeAry = [this.see1];
         this.allContainer = this.c as MovieClip;
         this.btnGTips = this.btngtips as SimpleButton;
         this.btnGTips.useHandCursor = false;
         this.mcGTips = this.mcgtips as MovieClip;
         this.mcGTips.visible = false;
         this.mcGTips.mouseChildren = this.mcGTips.mouseEnabled = false;
         TipsManager.getInstance().addMaterialTips(this);
      }
      
      private function initFuns() : void
      {
         var _loc1_:Sprite = null;
         for each(_loc1_ in this.canSeeAry)
         {
            _loc1_.addEventListener(MouseEvent.ROLL_OUT,this.onRoll);
            _loc1_.addEventListener(MouseEvent.ROLL_OVER,this.onRoll);
         }
         this.btnGTips.addEventListener(MouseEvent.ROLL_OUT,this.onRollGenius);
         this.btnGTips.addEventListener(MouseEvent.ROLL_OVER,this.onRollGenius);
      }
      
      private function disposeFuns() : void
      {
         var _loc1_:Sprite = null;
         this.btnGTips.removeEventListener(MouseEvent.ROLL_OUT,this.onRollGenius);
         this.btnGTips.removeEventListener(MouseEvent.ROLL_OVER,this.onRollGenius);
         for each(_loc1_ in this.canSeeAry)
         {
            _loc1_.removeEventListener(MouseEvent.ROLL_OUT,this.onRoll);
            _loc1_.removeEventListener(MouseEvent.ROLL_OVER,this.onRoll);
         }
      }
      
      private function loadScene(param1:String, param2:String) : void
      {
         var _loc3_:SceneExtInfo = new SceneExtInfo();
         _loc3_.arrowInfos = [param2];
         SceneManager.getInstance().loadScene(param1,"default",false,false,FaceDirectionTypes.FACELEFTDOWN,_loc3_);
      }
      
      private function onRoll(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         if(param1.type == MouseEvent.ROLL_OVER)
         {
            _loc2_ = int(this.canSeeAry.indexOf(param1.currentTarget));
            this.updateCanSee(_loc2_);
         }
         else
         {
            this.updateCanSee(-1);
         }
      }
      
      override protected function initUI() : void
      {
         var thisObj:DisplayObjectContainer = this;
         ServiceContainer.instance.tryGetService(IPetUIService,function(param1:IPetUIService, param2:Object):void
         {
            petUIService = param1;
            canUpdateUI = true;
            tryRefreshUI();
         });
      }
      
      override protected function refreshUI() : void
      {
         this.updateView();
      }
      
      override protected function resetUI() : void
      {
         var _loc2_:DisplayObject = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.txtTotalAttributes.length)
         {
            TextField(this.txtTotalAttributes[_loc1_]).text = "000";
            TextField(this.txtEffs[_loc1_]).text = "000";
            TextField(this.txtGenius[_loc1_]).text = "000";
            this.mcDefaultInd.getChildByName("mcd" + _loc1_).visible = false;
            _loc1_++;
         }
         for each(_loc2_ in this.indStars)
         {
            DisplayUtil.stopAndRemove(_loc2_);
         }
         this.txtCharacter.text = "未知";
         this.updateCanSee(-1);
         if(null != this.mcGenius)
         {
            DisplayUtil.stopAndRemove(this.mcGenius);
         }
      }
      
      private function onRollGenius(param1:MouseEvent) : void
      {
         this.mcGTips.visible = param1.type == MouseEvent.ROLL_OVER;
      }
      
      private function updateView() : void
      {
         var _loc4_:Array = null;
         var _loc5_:Array = null;
         var _loc6_:Array = null;
         var _loc7_:Array = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:Array = null;
         var _loc11_:int = 0;
         var _loc12_:int = 0;
         var _loc13_:Vector.<Ability> = null;
         var _loc14_:Ability = null;
         var _loc15_:int = 0;
         var _loc16_:int = 0;
         var _loc17_:int = 0;
         var _loc18_:MovieClip = null;
         var _loc19_:int = 0;
         var _loc20_:Sprite = null;
         var _loc1_:Array = this.getTotalAbility(pdi);
         var _loc2_:Boolean = Boolean(this.pmService.getOperationPM(pdi.raceId).pmData.isXinghuiPM());
         var _loc3_:Boolean = Boolean(Pet_Helper.checkPetIsGQPet(pdi.raceId));
         if(_loc3_ && pdi.usingGQSkillType == 1)
         {
            this.refreshNewGQPetAtt();
            return;
         }
         if(pdi == null || !(Boolean(this.pmService.getOperationPM(pdi.raceId).pmData.isXinghuiPM()) || this.isCurSelectSoulCardPet(pdi.raceId)))
         {
            this.allContainer.visible = true;
            this.gotoAndStop(1);
            TipsManager.getInstance().addMaterialTips(this);
            this.initPars();
            this.initFuns();
            _loc4_ = this.getGenius(pdi);
            _loc5_ = this.getEffs(pdi);
            _loc6_ = this.getMiraclePetAppend(pdi);
            _loc7_ = this.getCompletePMAppend(pdi);
            this.resetUI();
            _loc8_ = 0;
            _loc9_ = 0;
            while(_loc9_ < this.txtTotalAttributes.length)
            {
               if(_loc9_ == 0)
               {
                  TextField(this.txtTotalAttributes[_loc9_]).text = "" + _loc1_[_loc9_];
               }
               else
               {
                  TextField(this.txtTotalAttributes[_loc9_]).text = "" + (_loc1_[_loc9_] + int(_loc6_[_loc9_]) + int(_loc7_[_loc9_]));
               }
               TextField(this.txtEffs[_loc9_]).text = "" + _loc5_[_loc9_];
               _loc8_ += _loc5_[_loc9_];
               TextField(this.txtGenius[_loc9_]).text = "" + _loc4_[_loc9_];
               _loc9_++;
            }
            _loc10_ = [pdi.indAtt,pdi.indSAtt,pdi.indDef,pdi.indSDef,pdi.indHP,pdi.indSpd];
            _loc11_ = Pet_Helper.checkPetIsXingHuiPet(pdi.raceId) ? 6 : 5;
            _loc12_ = 0;
            while(_loc12_ < _loc10_.length)
            {
               _loc20_ = this.petUIService.getGeniusStarsByInds(_loc10_[_loc12_],_loc11_);
               _loc20_.x = START_POS.x;
               _loc20_.y = START_POS.y + OFFSET * _loc12_;
               this.allContainer.addChild(_loc20_);
               this.indStars.push(_loc20_);
               _loc12_++;
            }
            _loc13_ = this.pmService.getOperationPM(pdi.raceId).getRecommendAbility();
            for each(_loc14_ in _loc13_)
            {
               this.mcDefaultInd.getChildByName("mcd" + _loc14_.ability).visible = true;
            }
            this.txtCharacter.text = PetCharacterMap.getPetCharacterMyDesc(pdi.character,pdi.character + "(↑++++ ↓----)");
            _loc15_ = int(GeniusHelper.getTotalStarNumber(pdi.ind.arrayData));
            _loc16_ = int(GeniusHelper.getGeniusFrameIndex(pdi.ind.arrayData));
            MovieClip(this.mcGTips.getChildByName("mcGenius")).gotoAndStop(_loc16_);
            _loc17_ = int(GeniusHelper.getNextLevelStarNumber(_loc15_));
            _loc18_ = this.mcGTips.getChildByName("mcinfo") as MovieClip;
            _loc17_ = int(GeniusHelper.getNextLevelNeedGeniusVal(pdi.ind.arrayData));
            _loc18_.visible = !GeniusHelper.isFull(pdi.ind.arrayData);
            TextField(_loc18_.txtneed).text = _loc17_ + "";
            this.mcGenius = this.petUIService.getGeniusIconByPDI(pdi);
            this.mcGenius.x = GENIUS_POINT.x;
            this.mcGenius.y = GENIUS_POINT.y;
            this.allContainer.addChild(this.mcGenius);
            ActComHelper.setTxtValue(this,"txtlevel","Lv" + pdi.level);
            ActComHelper.setTxtValue(this,"txtstudy",_loc8_ + "/" + PetPackageConfig.getMaxStudy());
            _loc19_ = pdi == null ? 0 : int(GeniusHelper.getGeniusFrameIndex(pdi.ind.arrayData));
            ActComHelper.setMcFrame(this,"mcgeniusname",_loc19_);
         }
         else
         {
            this.gotoAndStop(2);
            this.refreshPetAtt_1();
         }
      }
      
      private function refreshNewGQPetAtt() : void
      {
         this.gotoAndStop(3);
         ActTipsMcHelper.bindTipsOnce(this,0,1,"mcSpecialAttTarget_","mcSpecialAttContent_");
         this.refreshPetAtt_1();
         var _loc1_:MovieClip = ActComHelper.getChildNode(this,"mcSpecialAttContent_0") as MovieClip;
         this.updateGQExtraAbilityFunc(this.pdi,_loc1_);
      }
      
      private function refreshPetAtt_1() : void
      {
         var _loc23_:String = null;
         var _loc24_:Array = null;
         var _loc26_:String = null;
         var _loc1_:Array = this.getTotalAbility(pdi);
         this.allContainer.visible = false;
         TipsManager.getInstance().addMaterialTips(this);
         TipsManager.getInstance().replaceTips(this.mcbasetips,"由亚比的种族值及等级共同影响");
         var _loc2_:String = "由性格、军团";
         var _loc3_:String = XinghuiPetType.getXinghuiAppendName(pdi.raceId);
         if(_loc3_.length > 0)
         {
            _loc2_ += "及#" + _loc3_ + "#";
         }
         TipsManager.getInstance().replaceTips(this.mcothertips,_loc2_ + "组成");
         var _loc4_:Array = this.getBaseAbility(pdi);
         var _loc5_:Array = this.getEquipAbility(pdi);
         var _loc6_:Array = this.getAstralSpiritAbility(pdi);
         var _loc7_:Array = this.getGodcardAbility(pdi);
         var _loc8_:Array = this.getGeniusAbility(pdi);
         var _loc9_:Array = this.getPetCorpsAbility(pdi);
         var _loc10_:Array = this.getCharacterAbility(pdi);
         var _loc11_:Array = this.getOtherAbility(pdi);
         var _loc12_:Array = this.getHKAbility(pdi);
         var _loc13_:Array = this.getToteAbility(pdi);
         this.txtTotalAttributes = [this.txt_hp,this.txt_attack,this.txt_defence,this.txt_sattack,this.txt_sdefence,this.txt_speed];
         var _loc14_:Array = [this.txt_bhp,this.txt_battack,this.txt_bdefence,this.txt_bsattack,this.txt_bsdefence,this.txt_bspeed];
         var _loc15_:Array = [this.txt_ehp,this.txt_eattack,this.txt_edefence,this.txt_esattack,this.txt_esdefence,this.txt_espeed];
         var _loc16_:Array = [this.txt_ahp,this.txt_aattack,this.txt_adefence,this.txt_asattack,this.txt_asdefence,this.txt_aspeed];
         var _loc17_:Array = [this.txt_ghp,this.txt_gattack,this.txt_gdefence,this.txt_gsattack,this.txt_gsdefence,this.txt_gspeed];
         var _loc18_:Array = [this.txt_xhp,this.txt_xattack,this.txt_xdefence,this.txt_xsattack,this.txt_xsdefence,this.txt_xspeed];
         var _loc19_:Array = [this.txt_tohp,this.txt_toattack,this.txt_todefence,this.txt_tosattack,this.txt_tosdefence,this.txt_tospeed];
         var _loc20_:Array = [this.mcotherhptips,this.mcotherattacktips,this.mcotherdefencetips,this.mcothersattacktips,this.mcothersdefencetips,this.mcotherspeedtips];
         var _loc21_:Boolean = Boolean(XinghuiPetType.isShenbinPet(pdi.raceId));
         var _loc22_:Boolean = this.isCurSelectSoulCardPet(pdi.raceId);
         ActComHelper.setVisible(this,"mcGQAbility",false);
         if(_loc22_)
         {
            _loc23_ = "光启";
            ActComHelper.setVisible(this,"mcGQAbility",true);
            ActComHelper.setMcFrame(this,"mcSpecialName",3);
            _loc24_ = _loc12_;
            this.updateGQExtraAbility(pdi);
         }
         else if(_loc21_)
         {
            _loc23_ = "神兵";
            ActComHelper.setMcFrame(this,"mcSpecialName",1);
            _loc24_ = _loc7_;
         }
         else
         {
            _loc23_ = "星灵";
            ActComHelper.setMcFrame(this,"mcSpecialName",2);
            _loc24_ = _loc6_;
         }
         var _loc25_:int = 0;
         while(_loc25_ < this.txtTotalAttributes.length)
         {
            ActComHelper.setTxtValue(this,this.tryGetName(this.txtTotalAttributes[_loc25_]),"" + _loc1_[_loc25_]);
            ActComHelper.setTxtValue(this,this.tryGetName(_loc14_[_loc25_]),"" + _loc4_[_loc25_]);
            ActComHelper.setTxtValue(this,this.tryGetName(_loc15_[_loc25_]),"" + _loc5_[_loc25_]);
            ActComHelper.setTxtValue(this,this.tryGetName(_loc16_[_loc25_]),"" + _loc24_[_loc25_]);
            ActComHelper.setTxtValue(this,this.tryGetName(_loc17_[_loc25_]),"" + _loc8_[_loc25_]);
            ActComHelper.setTxtValue(this,this.tryGetName(_loc18_[_loc25_]),"" + _loc11_[_loc25_]);
            ActComHelper.setTxtValue(this,this.tryGetName(_loc19_[_loc25_]),"" + _loc13_[_loc25_]);
            _loc26_ = _loc10_[_loc25_] + "+" + Math.ceil(_loc9_[_loc25_]);
            if(_loc3_.length > 0)
            {
               _loc26_ += "+" + pdi.xinghuiPetExtraAppend.arrayData[_loc25_];
            }
            TipsManager.getInstance().replaceTips(_loc20_[_loc25_],_loc26_);
            _loc25_++;
         }
      }
      
      private function tryGetName(param1:DisplayObject) : String
      {
         if(param1 == null)
         {
            return "";
         }
         return param1.name;
      }
      
      private function updateCanSee(param1:int) : void
      {
         var _loc2_:int = 0;
         while(_loc2_ < this.unseenAry.length)
         {
            this.setCanSee(this.unseenAry[_loc2_],_loc2_ == param1);
            _loc2_++;
         }
      }
      
      private function setCanSee(param1:*, param2:Boolean) : *
      {
         var _loc3_:TextField = null;
         if(param1 is Array)
         {
            for each(_loc3_ in param1 as Array)
            {
               _loc3_.visible = param2;
            }
         }
         else if(param1 is DisplayObject)
         {
            DisplayObject(param1).visible = param2;
         }
      }
      
      private function getAppenStr(param1:int) : String
      {
         return (param1 < 0 ? "↓" : "↑") + Math.abs(param1);
      }
      
      override public function dispose() : void
      {
         var _loc1_:Sprite = null;
         this.disposeFuns();
         this.resetUI();
         for each(_loc1_ in this.mcEffs)
         {
            TipsManager.getInstance().removeTips(_loc1_);
         }
         DisplayUtil.stopAndRemove(this.mcGenius);
         super.dispose();
      }
      
      private function getTotalAbility(param1:PetDetailedInfo) : Array
      {
         var _loc3_:int = 0;
         var _loc2_:Array = [0,0,0,0,0,0];
         if(param1 == null)
         {
            return defaultData;
         }
         _loc3_ = 0;
         while(_loc3_ < 6)
         {
            _loc2_[_loc3_] = param1.max.arrayData[_loc3_] + Math.ceil(this.petCorpsSvr.getTotalAddAbilitys()[_loc3_]);
            _loc3_++;
         }
         return _loc2_;
      }
      
      private function getBaseAbility(param1:PetDetailedInfo) : Array
      {
         if(param1 == null)
         {
            return defaultData;
         }
         return param1.base.arrayData;
      }
      
      private function getEquipAbility(param1:PetDetailedInfo) : Array
      {
         if(param1 == null)
         {
            return defaultData;
         }
         return param1.apend.arrayData;
      }
      
      private function getAstralSpiritAbility(param1:PetDetailedInfo) : Array
      {
         if(param1 == null)
         {
            return defaultData;
         }
         return param1.astralSpiritExtraAppend.arrayData;
      }
      
      private function getGodcardAbility(param1:PetDetailedInfo) : Array
      {
         if(param1 == null)
         {
            return defaultData;
         }
         return param1.godcardExtraAppend.arrayData;
      }
      
      private function getGeniusAbility(param1:PetDetailedInfo) : Array
      {
         if(param1 == null)
         {
            return defaultData;
         }
         return param1.geniusExtraAppend.arrayData;
      }
      
      private function getPetCorpsAbility(param1:PetDetailedInfo) : Array
      {
         if(param1 == null)
         {
            return defaultData;
         }
         return this.petCorpsSvr.getTotalAddAbilitys();
      }
      
      private function getCharacterAbility(param1:PetDetailedInfo) : Array
      {
         if(param1 == null)
         {
            return defaultData;
         }
         return param1.characterExtraAppend.arrayData;
      }
      
      private function getHKAbility(param1:PetDetailedInfo) : Array
      {
         if(param1 == null)
         {
            return defaultData;
         }
         return param1.hkAppend.arrayData;
      }
      
      private function getToteAbility(param1:PetDetailedInfo) : Array
      {
         if(param1 == null)
         {
            return defaultData;
         }
         return param1.toteAppend.arrayData;
      }
      
      private function getOtherAbility(param1:PetDetailedInfo) : Array
      {
         var _loc3_:int = 0;
         var _loc2_:Array = [0,0,0,0,0,0];
         if(param1 == null)
         {
            return defaultData;
         }
         _loc3_ = 0;
         while(_loc3_ < 6)
         {
            _loc2_[_loc3_] = param1.characterExtraAppend.arrayData[_loc3_] + Math.ceil(this.petCorpsSvr.getTotalAddAbilitys()[_loc3_]) + param1.xinghuiPetExtraAppend.arrayData[_loc3_];
            _loc3_++;
         }
         return _loc2_;
      }
      
      private function getAppend(param1:PetDetailedInfo) : Array
      {
         if(null == param1)
         {
            return defaultData;
         }
         return param1.apend.arrayData;
      }
      
      private function getCompletePMAppend(param1:PetDetailedInfo) : Array
      {
         var _loc2_:IPMService = null;
         var _loc3_:PMData = null;
         if(null == param1)
         {
            return defaultData;
         }
         _loc2_ = ServiceContainer.getService(IPMService) as IPMService;
         _loc3_ = _loc2_.customData.pmDataMap.getPM(param1.raceId);
         if(Boolean(_loc3_.isCompletePM()) && Boolean(_loc3_.isMiraclePet()))
         {
            return _loc2_.getCompleteMiraclePMData(param1.raceId).addedAttribute;
         }
         return defaultData;
      }
      
      private function getMiraclePetAppend(param1:PetDetailedInfo) : Array
      {
         var _loc2_:IPMService = null;
         var _loc3_:PMData = null;
         var _loc4_:IMiraclePetDataService = null;
         var _loc5_:MiraclePetBreakData = null;
         var _loc6_:Array = null;
         var _loc7_:MiraclePetInfo = null;
         var _loc8_:Array = null;
         var _loc9_:Array = null;
         var _loc10_:int = 0;
         if(null == param1)
         {
            return defaultData;
         }
         _loc2_ = ServiceContainer.getService(IPMService) as IPMService;
         _loc3_ = _loc2_.customData.pmDataMap.getPM(param1.raceId);
         if(Boolean(_loc3_.isMiraclePet()) && !_loc3_.isCompletePM())
         {
            _loc4_ = ServiceContainer.getService(IMiraclePetDataService) as IMiraclePetDataService;
            _loc5_ = _loc4_.getMiraclePetBreakDataByRaceId(param1.raceId);
            _loc6_ = _loc5_.getBreakMaterialAddAbility(param1.curEquipedMiracleBreakMaterialNum).arrayData;
            _loc7_ = _loc4_.getMiraclePetInfo(param1.raceId);
            _loc8_ = _loc7_.baseAbility.arrayData;
            _loc9_ = [];
            _loc10_ = 0;
            while(_loc10_ < 6)
            {
               _loc9_[_loc10_] = _loc6_[_loc10_] + _loc8_[_loc10_];
               _loc10_++;
            }
            return _loc9_;
         }
         return defaultData;
      }
      
      private function getAttributes(param1:PetDetailedInfo) : Array
      {
         if(null == param1)
         {
            return defaultData;
         }
         return param1.base.arrayData;
      }
      
      private function getEffs(param1:PetDetailedInfo) : Array
      {
         if(null == param1)
         {
            return defaultData;
         }
         return param1.eff.arrayData;
      }
      
      private function getGenius(param1:PetDetailedInfo) : Array
      {
         if(null == param1)
         {
            return defaultData;
         }
         return param1.ind.arrayData;
      }
      
      private function isCurSelectSoulCardPet(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         return _loc2_.customData.pmDataMap.getPM(param1).isGQPM();
      }
      
      private function updateGQExtraAbility(param1:PetDetailedInfo) : void
      {
         var _loc2_:MovieClip = this.getChildByName("mcGQAbility") as MovieClip;
         this.updateGQExtraAbilityFunc(this.pdi,_loc2_);
      }
      
      private function updateGQExtraAbilityFunc(param1:PetDetailedInfo, param2:MovieClip) : void
      {
         var _loc8_:Boolean = false;
         var _loc9_:String = null;
         if(param2 == null)
         {
            return;
         }
         var _loc3_:Array = param1.getGQExtraAbility();
         var _loc4_:Array = [];
         var _loc5_:int = 0;
         var _loc6_:Array = [4,5,6];
         var _loc7_:int = 0;
         while(_loc7_ < _loc3_.length)
         {
            ActComHelper.refreshObj(param2,"mcAttr" + _loc7_,false,"",this._gqAbilityDescArr[_loc7_]);
            _loc4_ = _loc3_[_loc7_];
            _loc5_ = 0;
            _loc8_ = Boolean(ActArrHelper.isContainerValue(_loc6_,_loc7_));
            if(_loc4_.length > 9)
            {
               if(_loc8_)
               {
                  _loc5_ = _loc4_[0] + _loc4_[9] + _loc4_[10];
               }
               else
               {
                  _loc5_ = _loc4_[0] + _loc4_[2] + _loc4_[4] + _loc4_[5] + _loc4_[7] + _loc4_[9] + _loc4_[10];
               }
            }
            _loc9_ = _loc8_ ? "" : "%";
            ActComHelper.setTxtValue(param2,"txt_extra" + _loc7_ + "0",_loc5_ + _loc9_);
            ActComHelper.setTxtValue(param2,"txt_extra" + _loc7_ + "1",_loc4_.length > 0 ? _loc4_[0] + "" : "0");
            ActComHelper.setTxtValue(param2,"txt_extra" + _loc7_ + "2",_loc4_.length > 2 ? _loc4_[2] + "" : "0");
            ActComHelper.setTxtValue(param2,"txt_extra" + _loc7_ + "3",_loc4_.length > 9 ? _loc4_[9] + "" : "0");
            ActComHelper.setTxtValue(param2,"txt_extra" + _loc7_ + "4",_loc4_.length > 4 ? _loc4_[4] + "" : "0");
            ActComHelper.setTxtValue(param2,"txt_extra" + _loc7_ + "5",_loc4_.length > 7 ? _loc4_[5] + _loc4_[7] + "" : "0");
            ActComHelper.setTxtValue(param2,"txt_extra" + _loc7_ + "6",_loc4_.length > 10 ? _loc4_[10] + "" : "0");
            _loc7_++;
         }
      }
   }
}

