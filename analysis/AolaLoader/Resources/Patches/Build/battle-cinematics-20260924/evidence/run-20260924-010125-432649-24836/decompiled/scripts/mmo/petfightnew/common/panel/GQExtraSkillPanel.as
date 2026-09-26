package mmo.petfightnew.common.panel
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.GQXingyueTongxingSkillParse;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.component.CachedClip;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.event.FightInnerEvent;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.skill.EffectIcon;
   import mmo.petfightnew.common.panel.skill.GQSmallSkillComponent;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActTipsMc;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2692")]
   public class GQExtraSkillPanel extends MovieClip
   {
      
      public var mcPassiveSkill:MovieClip;
      
      public var mcShenYuTianGang:MovieClip;
      
      public var mcYuxiangShi:MovieClip;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _pbi:PetBriefInfo = null;
      
      private var _passiveSkillList:Array = [];
      
      private var _gqType:int;
      
      private var _effectIcon:CachedClip;
      
      private var _skillCom:GQSmallSkillComponent = null;
      
      private var _fladId:int;
      
      private var _shenYuTianGangPanel:GQShenYuTianGangExtraSkillPanel;
      
      private var _yuXiangShiPanel:GQYuXiangShiExtraSkillPanel;
      
      public function GQExtraSkillPanel()
      {
         super();
         this.addEventListener(Event.REMOVED_FROM_STAGE,this.onRemoveFromStageListener);
      }
      
      public function setSkill(param1:PetBriefInfo, param2:Array) : void
      {
         this._pbi = param1;
         this._passiveSkillList = param2;
         this._gqType = this._pmSvr.getOperationPM(this._pbi.raceId).pmData.getGQType();
         this._fladId = PetAssetsMap.getPetFlaId(this._pbi.raceId);
         this.update();
      }
      
      private function update() : void
      {
         var onRollOverYuXiangShi:Function = null;
         var onRollOutYuXiangShi:Function = null;
         var skillInfo:SkillInfo = null;
         var xingyuetongxingSkillParse:GQXingyueTongxingSkillParse = null;
         var index:int = 0;
         var config:Object = null;
         var passiveSkillMc:MovieClip = null;
         var extraSkillBtn:SimpleButton = null;
         var shenYuTianGangMc:MovieClip = null;
         var pmSkill:PMSkill = null;
         var yuxiangshiMc:MovieClip = null;
         onRollOverYuXiangShi = function(param1:MouseEvent):void
         {
            var _loc2_:MovieClip = (param1.target as DisplayObjectContainer).getChildByName("mcYuxiangShi") as MovieClip;
            if(Boolean(_loc2_) && Boolean(_loc2_.parent))
            {
               _loc2_.visible = true;
            }
         };
         onRollOutYuXiangShi = function(param1:MouseEvent):void
         {
            var _loc2_:MovieClip = (param1.target as DisplayObjectContainer).getChildByName("mcYuxiangShi") as MovieClip;
            if(Boolean(_loc2_) && Boolean(_loc2_.parent))
            {
               _loc2_.visible = false;
            }
         };
         if(this._pbi.usingGQSkillType == 1 && !GQPetType.isAdaptSystem(this._gqType,this._pbi))
         {
            this.visible = false;
            return;
         }
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.ON_MOUSE_OVER_PET,this.onMouseRoleOverPetListener);
         if(GQPetType.isEternityContract(this._gqType))
         {
            this.gotoAndStop(this._gqType);
            this.eternityContractHandle(this.getChildByName("mcPassiveSkill") as MovieClip);
         }
         else if(GQPetType.isMingZuo(this._gqType))
         {
            this.gotoAndStop(this._gqType);
            this.mingzuoHandle(this.getChildByName("mcPassiveSkill") as MovieClip);
         }
         else if(GQPetType.isChaoWei(this._gqType))
         {
            this.gotoAndStop(this._gqType);
            this.addCommondIcon(this.getChildByName("mcPassiveSkill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(GQPetType.isOutburstCopy(this._gqType))
         {
            this.gotoAndStop(this._gqType);
            this.addCommondIcon(this.getChildByName("mcPassiveSkill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(GQPetType.isTianYi(this._gqType))
         {
            this.gotoAndStop(this._gqType);
            this.addCommondIcon(this.getChildByName("mcPassiveSkill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(GQPetType.isShengHun(this._gqType))
         {
            this.gotoAndStop(this._gqType);
            this._skillCom && this._skillCom.dispose();
            this._skillCom = new GQSmallSkillComponent(this._pbi.raceId,this.getChildByName("mcPassiveSkill") as MovieClip);
            skillInfo = new SkillInfo();
            skillInfo.parseInfo({
               "id":this._passiveSkillList[0].id,
               "pp":"0/0"
            });
            this._skillCom.refresh(skillInfo);
            this.shengHunHandle(this.getChildByName("mcPassiveSkill") as MovieClip);
            this.addCommondIcon(this.getChildByName("mcPassiveSkill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(GQPetType.isQuanNeng(this._gqType))
         {
            this.gotoAndStop(this._gqType);
            this.addCommondIcon(this.getChildByName("mcPassiveSkill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(Boolean(GQPetType.isXingyueTongxing(this._gqType)) && this._passiveSkillList.length > 0)
         {
            this.gotoAndStop(this._gqType);
            xingyuetongxingSkillParse = GQXingyueTongxingSkillParse.getXingyueTongxingSkillParse(this._pbi.raceId);
            index = int(xingyuetongxingSkillParse.getExtraSkillIndex(this._pbi));
            config = GQPetType.getXingyueTongxingObject(this._pbi.raceId % 10000);
            index = config == null ? index : int((config["iconFrame"] - 1) * 2 + index);
            passiveSkillMc = this.getChildByName("mcPassiveSkill") as MovieClip;
            this.addCommondIcon(passiveSkillMc,this._passiveSkillList[0].id,index + 1);
            extraSkillBtn = passiveSkillMc.getChildByName("btnExtraSkill") as SimpleButton;
            extraSkillBtn.addEventListener(MouseEvent.CLICK,this.onClickSkill);
         }
         else if(GQPetType.isMenghuanDiyue(this._gqType))
         {
            this.gotoAndStop(this._gqType);
            passiveSkillMc = this.getChildByName("mcPassiveSkill") as MovieClip;
            ActComHelper.setMcFrame(passiveSkillMc,"mcBg",this._fladId == 5564 || this._fladId == 5565 ? 1 : 2);
            this._skillCom && this._skillCom.dispose();
            this._skillCom = new GQSmallSkillComponent(this._pbi.raceId,passiveSkillMc);
            skillInfo = new SkillInfo();
            skillInfo.parseInfo({
               "id":this._passiveSkillList[0].id,
               "pp":"0/0"
            });
            this._skillCom.refresh(skillInfo);
            this.addCommondIcon(this.getChildByName("mcPassiveSkill") as MovieClip,this._passiveSkillList[0].id);
         }
         else if(GQPetType.isShuangShenGe(this._gqType))
         {
            this.gotoAndStop(this._gqType);
            passiveSkillMc = this.getChildByName("mcPassiveSkill") as MovieClip;
            this.addCommondIcon(passiveSkillMc,this._passiveSkillList[0].id);
            extraSkillBtn = passiveSkillMc.getChildByName("btnExtraSkill") as SimpleButton;
            extraSkillBtn.addEventListener(MouseEvent.CLICK,this.onClickSkill);
         }
         else if(GQPetType.isShenYuTianGang(this._gqType))
         {
            this._shenYuTianGangPanel && this._shenYuTianGangPanel.dispose();
            this.gotoAndStop(this._gqType);
            passiveSkillMc = this.getChildByName("mcPassiveSkill") as MovieClip;
            shenYuTianGangMc = this.getChildByName("mcShenYuTianGang") as MovieClip;
            new ActTipsMc().init(passiveSkillMc,shenYuTianGangMc);
            this._shenYuTianGangPanel = new GQShenYuTianGangExtraSkillPanel(this._pbi,shenYuTianGangMc);
         }
         else if(GQPetType.isYuXiangShi(this._gqType))
         {
            pmSkill = this._pmSvr.customData.pmSkillMap.getSkill(this._passiveSkillList[0].id);
            this._yuXiangShiPanel && this._yuXiangShiPanel.dispose();
            this.gotoAndStop(this._gqType);
            passiveSkillMc = this.getChildByName("mcPassiveSkill") as MovieClip;
            this.addCommondIcon(passiveSkillMc,this._passiveSkillList[0].id);
            extraSkillBtn = passiveSkillMc.getChildByName("btnExtraSkill") as SimpleButton;
            yuxiangshiMc = this.getChildByName("mcYuxiangShi") as MovieClip;
            yuxiangshiMc.visible = false;
            ActComHelper.refreshObj(this,"mcPassiveSkill",false,"");
            if(StatusUtil.getIsInYuXiangState(this._pbi))
            {
               extraSkillBtn.visible = false;
               extraSkillBtn.removeEventListener(MouseEvent.CLICK,this.onClickYuXiangShiSkill);
               this.addEventListener(MouseEvent.ROLL_OVER,onRollOverYuXiangShi);
               this.addEventListener(MouseEvent.ROLL_OUT,onRollOutYuXiangShi);
               this._yuXiangShiPanel = new GQYuXiangShiExtraSkillPanel(this._pbi,yuxiangshiMc,this._passiveSkillList[0].id);
            }
            else
            {
               extraSkillBtn.visible = true;
               if(FightData.instance.myInfo.isSkillUsed(this._pbi.id,this._passiveSkillList[0].id))
               {
                  ActComHelper.refreshObj(this,"mcPassiveSkill",true,"已使用");
               }
               else if(!StatusUtil.getYuXiangShiIsCanUseFirstSkill(this._pbi))
               {
                  ActComHelper.refreshObj(this,"mcPassiveSkill",true,"本场次数用完");
               }
               else
               {
                  extraSkillBtn.addEventListener(MouseEvent.CLICK,this.onClickYuXiangShiSkill);
               }
            }
         }
      }
      
      private function shengHunHandle(param1:MovieClip) : void
      {
         var _loc6_:String = null;
         if(this.haveOnlyOneEnemy())
         {
            this.updateEffectIcon(FightData.instance.opponents[0]);
         }
         else
         {
            FightEventDispatcher.instance.addEventListener(FightInnerEvent.ON_MOUSE_OVER_PET,this.onMouseRoleOverPetListener);
         }
         var _loc2_:MovieClip = ActComHelper.getChildNode(param1,"mcPro") as MovieClip;
         var _loc3_:int = 0;
         var _loc4_:int = 1;
         var _loc5_:Array = this._pbi.status.split(",");
         for each(_loc6_ in _loc5_)
         {
            if(_loc6_.indexOf("gqshp") != -1)
            {
               _loc3_ = parseInt(_loc6_.split("_")[1]);
               _loc4_ = parseInt(_loc6_.split("_")[2]);
               break;
            }
         }
         _loc2_.gotoAndStop(Math.floor(_loc3_ * (_loc2_.totalFrames - 1) / _loc4_) + 1);
      }
      
      private function onClickSkill(param1:MouseEvent) : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FightUseCustomSkill,{"skillId":this._passiveSkillList[0].id}));
      }
      
      private function onClickYuXiangShiSkill(param1:MouseEvent) : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FightUseCustomSkill,{"skillId":this._passiveSkillList[0].id}));
      }
      
      private function haveOnlyOneEnemy() : Boolean
      {
         return FightData.instance.opponents.length == 1;
      }
      
      private function onMouseRoleOverPetListener(param1:CommonEvent) : void
      {
         var _loc2_:int = int(param1.params.locaId);
         if(FightData.instance.isMySide(_loc2_))
         {
            return;
         }
         if(FightData.instance.opponents.length <= 1)
         {
            return;
         }
         this.updateEffectIcon(FightData.instance.getPlayerInfoByLocalId(_loc2_));
      }
      
      private function updateEffectIcon(param1:PlayerBattleInfo) : void
      {
         var _loc5_:Object = null;
         var _loc8_:PlayerBattleInfo = null;
         var _loc9_:MovieClip = null;
         var _loc2_:PetBriefInfo = param1.myPets[0];
         if(_loc2_ == null)
         {
            return;
         }
         if(!this._passiveSkillList || this._passiveSkillList.length <= 0)
         {
            return;
         }
         var _loc3_:MovieClip = this.getChildByName("mcPassiveSkill") as MovieClip;
         var _loc4_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         if(param1.lingshouRealitySlotId == -1)
         {
            _loc5_ = _loc4_.getPetMes(_loc2_.raceId);
         }
         else
         {
            _loc8_ = FightData.instance.getPlayerInfoBySlotId(param1.lingshouRealitySlotId);
            _loc5_ = _loc4_.getPetMes((_loc8_.myPets[0] as PetBriefInfo).raceId);
         }
         var _loc6_:Object = _loc4_.getPetSkillMes(this._passiveSkillList[0].id);
         var _loc7_:int = _loc4_.compareAttributeRelation(_loc6_.attribute,_loc5_.attribute,_loc5_.attribute2) + 1;
         if(this._effectIcon == null)
         {
            _loc9_ = new EffectIcon();
            this._effectIcon = new CachedClip(_loc9_);
            this._effectIcon.x = -28;
            this._effectIcon.y = 15;
         }
         this._effectIcon.gotoAndStop(_loc7_);
         _loc3_.addChild(this._effectIcon);
      }
      
      private function eternityContractHandle(param1:MovieClip) : void
      {
         var _loc4_:MovieClip = null;
         var _loc2_:Object = GQPetType.getEternityContractObject(this._pbi.raceId);
         if(!_loc2_)
         {
            param1.gotoAndStop(1);
            param1.visible = false;
            return;
         }
         param1.gotoAndStop(_loc2_.extraSkillFrame);
         param1.visible = true;
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.extraSkillMaxNum)
         {
            _loc4_ = param1.getChildByName("mcSkill_" + _loc3_) as MovieClip;
            if(_loc3_ < this._passiveSkillList.length)
            {
               this.addCommondIcon(_loc4_,this._passiveSkillList[_loc3_].id,2);
            }
            else
            {
               _loc4_.gotoAndStop(1);
               TipsManager.getInstance().addTips(_loc4_,"敬请期待");
            }
            _loc3_++;
         }
      }
      
      private function mingzuoHandle(param1:MovieClip) : void
      {
         var _loc2_:Object = GQPetType.getMingZuoObject(this._pbi.raceId);
         if(!_loc2_)
         {
            param1.gotoAndStop(1);
            param1.visible = false;
            return;
         }
         param1.gotoAndStop(_loc2_.extraSkillFrame);
         param1.visible = true;
         var _loc3_:MovieClip = param1.getChildByName("mcSkill") as MovieClip;
         if(this._passiveSkillList.length > 0 && this._passiveSkillList[0] != null)
         {
            this.addCommondIcon(_loc3_,this._passiveSkillList[0].id,2);
         }
         else
         {
            _loc3_.gotoAndStop(1);
            TipsManager.getInstance().addTips(_loc3_,"该技能未解锁，请前往激活命座进行解锁");
         }
      }
      
      private function addCommondIcon(param1:MovieClip, param2:int, param3:int = 1) : void
      {
         param1.gotoAndStop(param3);
         var _loc4_:PMSkill = this._pmSvr.customData.pmSkillMap.getSkill(param2);
         TipsManager.getInstance().replaceComplexTips(param1,this.getSkillTipsTitle(_loc4_),this.getSkillTipsContent(_loc4_),0,9,-50);
      }
      
      private function getSkillTipsTitle(param1:PMSkill) : String
      {
         return param1.newCnName + "  " + this.getSkillAttackTypeDesc(param1.attackType);
      }
      
      private function getSkillTipsContent(param1:PMSkill) : String
      {
         return "威力:" + param1.power + "\n" + param1.clientDesc;
      }
      
      private function getSkillAttackTypeDesc(param1:int) : String
      {
         switch(param1)
         {
            case 0:
               return "(普通攻击)";
            case 1:
               return "(特殊攻击)";
            case 2:
               return "(属性攻击)";
            default:
               return "";
         }
      }
      
      private function onRemoveFromStageListener(param1:Event) : void
      {
         this.removeEventListener(Event.REMOVED_FROM_STAGE,this.onRemoveFromStageListener);
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.ON_MOUSE_OVER_PET,this.onMouseRoleOverPetListener);
         this._skillCom && this._skillCom.dispose();
         this._skillCom = null;
         this._shenYuTianGangPanel && this._shenYuTianGangPanel.dispose();
         this._yuXiangShiPanel && this._yuXiangShiPanel.dispose();
         if(this._effectIcon)
         {
            this._effectIcon.dispose();
            DisplayUtil.stopAndRemove(this._effectIcon);
            this._effectIcon = null;
         }
      }
   }
}

