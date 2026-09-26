package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetCharacterMap;
   import mmo.interfaces.pet.data.petbattleeff.PetBattleDetectHelper;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petpackage.controller.helper.AddPetDetailInfoHelper;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2900")]
   public class PetCharactorInfo extends PetDetailBase
   {
      
      public var btnGoCharacter:SimpleButton;
      
      public var btnhowcharactor:SimpleButton;
      
      public var mcEffProg:MovieClip;
      
      public var mc_character:MovieClip;
      
      public var txtEff:TextField;
      
      public var txt_character0:TextField;
      
      public var txt_character1:TextField;
      
      public var txt_reco_character:TextField;
      
      public function PetCharactorInfo()
      {
         super();
      }
      
      override protected function initUI() : void
      {
         AddPetDetailInfoHelper.addDetailInfoMC(3,this,this.setCanUpdate);
         this.btnGoCharacter.addEventListener(MouseEvent.CLICK,this.onClickCharacter);
      }
      
      override protected function refreshUI() : void
      {
         var _loc3_:String = null;
         var _loc4_:IPMService = null;
         var _loc5_:PMData = null;
         var _loc6_:Array = null;
         var _loc1_:int = int(PetBattleDetectHelper.getDetectNumByType(5,pdi));
         var _loc2_:int = int(PetBattleDetectHelper.getMaxNum(pdi,5));
         ActComHelper.setMcProg(ActComHelper.getChildNode(this,"mcEffProg") as MovieClip,[0,_loc2_],[0,100],_loc1_);
         ActComHelper.setTxtValue(this,"txtEff",Math.floor(_loc1_ * 100 / _loc2_) + "%");
         if(pdi == null)
         {
            this.mc_character.visible = false;
            this.txt_reco_character.text = "未知";
         }
         else
         {
            _loc3_ = PetCharacterMap.getPetCharacterDesc(pdi.character);
            if(_loc3_.indexOf("_") != -1)
            {
               _loc6_ = _loc3_.split("_");
               this.txt_character0.htmlText = "基础<font color=\'#FFFF99\'>" + _loc6_[0] + "+10%</font>";
               this.txt_character1.htmlText = "基础<font color=\'#FF7070\'>" + _loc6_[1] + "-10%</font>";
            }
            else
            {
               this.txt_character0.htmlText = "攻守";
               this.txt_character1.htmlText = "兼备";
            }
            this.mc_character.gotoAndStop(pdi.character);
            _loc4_ = ServiceContainer.getService(IPMService) as IPMService;
            _loc5_ = _loc4_.getOperationPM(pdi.raceId).pmData;
            this.txt_reco_character.text = PetCharacterMap.getPetCharacterMyDesc(_loc5_.pmRecommendatoryCharacter,_loc5_.pmRecommendatoryCharacter + "(↑++++ ↓----)");
         }
      }
      
      private function onClickCharacter(param1:MouseEvent) : void
      {
         ModalDialogManager.getInstance().clearAll();
         var _loc2_:String = "pet/character/petcharacter";
         var _loc3_:String = "mmo.petcharacter.PetCharacter_Main";
         Panel_Helper.loadResAndShow(_loc2_,_loc3_);
      }
   }
}

