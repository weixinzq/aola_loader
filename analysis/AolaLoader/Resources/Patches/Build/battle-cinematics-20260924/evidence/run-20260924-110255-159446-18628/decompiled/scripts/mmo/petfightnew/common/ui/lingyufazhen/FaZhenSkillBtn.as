package mmo.petfightnew.common.ui.lingyufazhen
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PlayerBattleFaZhenInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActPetLoader;
   
   public class FaZhenSkillBtn extends Sprite implements IDispose
   {
      
      private var BTN_CLS:String = "mmo.petfightnew.FaZhenBtn";
      
      private var _pmService:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var _view:MovieClip;
      
      private var _clickable:Boolean;
      
      private var _mcZhenYan:MovieClip;
      
      private var _petLoader:ActPetLoader;
      
      public function FaZhenSkillBtn()
      {
         super();
      }
      
      public function dispose() : void
      {
         DisplayUtil.stopAndRemove(this._view);
         this._view = null;
         this._mcZhenYan.removeEventListener(MouseEvent.CLICK,this.onClickZhenYan);
         this._mcZhenYan = null;
         this._pmService = null;
      }
      
      public function initView() : void
      {
         if(this._view != null)
         {
            return;
         }
         var _loc1_:Class = FightData.instance.applicationDomain.getDefinition(this.BTN_CLS) as Class;
         this._view = new _loc1_();
         this.addChild(this._view);
         this._mcZhenYan = this._view.getChildByName("mcZhenYan") as MovieClip;
         this._mcZhenYan.addEventListener(MouseEvent.CLICK,this.onClickZhenYan);
         this._petLoader = new ActPetLoader();
      }
      
      private function onClickZhenYan(param1:MouseEvent) : void
      {
         var _loc3_:int = 0;
         var _loc4_:PMSkill = null;
         var _loc2_:Boolean = this._clickable && !this.isUseSkillThisTurn() && this.getFaZhenInfo().skillCdTurn <= 0;
         if(_loc2_)
         {
            _loc3_ = int(this.getFaZhenInfo().skillId);
            _loc4_ = this._pmService.customData.pmSkillMap.getSkill(_loc3_);
            UseBigSkillHandler.instance.handleUse(null,_loc3_,_loc4_.getSkillType());
            this.getFaZhenInfo().isUseSkillThisTurn = true;
            this.refreshView();
         }
      }
      
      public function isUseSkillThisTurn() : Boolean
      {
         var _loc1_:PlayerBattleFaZhenInfo = this.getFaZhenInfo();
         if(_loc1_ != null)
         {
            return _loc1_.isUseSkillThisTurn;
         }
         return false;
      }
      
      public function refreshView() : void
      {
         var _loc3_:MovieClip = null;
         var _loc4_:int = 0;
         var _loc5_:MovieClip = null;
         var _loc6_:PMSkill = null;
         var _loc7_:String = null;
         var _loc8_:String = null;
         if(this._view == null)
         {
            return;
         }
         var _loc1_:PlayerBattleFaZhenInfo = this.getFaZhenInfo();
         var _loc2_:Boolean = Boolean(_loc1_.isUseSkillThisTurn);
         this.visible = _loc1_.skillId > 0;
         if(this.visible)
         {
            _loc3_ = this._view.getChildByName("mcTurn") as MovieClip;
            _loc4_ = _loc1_.skillCdTurn > 0 ? 1 : 2;
            _loc4_ = _loc2_ && _loc1_.skillCdTurn == 0 ? 3 : _loc4_;
            _loc3_.gotoAndStop(_loc4_);
            ActComHelper.setMcNum(_loc3_,"mcNum",_loc1_.skillCdTurn);
            this._mcZhenYan.buttonMode = _loc1_.skillCdTurn <= 0 && !_loc2_;
            this._mcZhenYan.gotoAndStop(_loc1_.faZhenType);
            this._mcZhenYan.mouseChildren = _loc1_.skillCdTurn == 0 && !_loc2_;
            if(_loc2_)
            {
               TipsManager.getInstance().replaceTips(this._mcZhenYan,"已使用了该技能！");
            }
            else
            {
               _loc6_ = this._pmService.customData.pmSkillMap.getSkill(_loc1_.skillId);
               _loc7_ = _loc6_.newCnName;
               _loc8_ = _loc6_.clientDesc;
               TipsManager.getInstance().replaceComplexTips(this._mcZhenYan,_loc7_,_loc8_,0,0,0);
            }
            _loc5_ = this._mcZhenYan["mcPetHead"];
            _loc5_.mouseEnabled = false;
            _loc5_.mouseChildren = false;
            this._petLoader.setPetView(_loc5_["mcView"],_loc1_.activieRaceId,PetIconType.FIGHT);
         }
      }
      
      private function getFaZhenInfo() : PlayerBattleFaZhenInfo
      {
         var _loc1_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         return _loc1_.faZhenInfo;
      }
      
      public function setClickable(param1:Boolean) : void
      {
         this._clickable = param1;
      }
   }
}

