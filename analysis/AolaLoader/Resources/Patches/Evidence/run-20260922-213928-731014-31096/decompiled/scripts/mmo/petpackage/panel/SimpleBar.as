package mmo.petpackage.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.astralspirit.AstralSpiritConfig;
   import mmo.interfaces.material.astralspirit.IAstralSpiritService;
   import mmo.interfaces.material.astralspirit.UserAstralSpirit;
   import mmo.interfaces.pet.data.EquipmentInfo;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.petbattleeff.PetBattleDetectHelper;
   import mmo.interfaces.pet.petcommon.GeniusHelper;
   import mmo.interfaces.pet.petpackage.IPetPackageService;
   import mmo.interfaces.pet.petpackage.PetPackageTabs;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petpackage.config.PetPackageConfig;
   import mmo.petpackage.controller.skin.PackageSkinManager;
   import mmo.petpackage.controller.skin.constant.Classify;
   import mmo.petpackage.panel.inclusion.petdetailinfo.PetDetailBase;
   import mmo.play.activity.material.MaterialContainer;
   import mmo.play.actthings.helper.ActMaterialLoader;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol913")]
   public class SimpleBar extends PetDetailBase
   {
      
      public var btn_0:SimpleButton;
      
      public var btn_1:SimpleButton;
      
      public var btn_2:SimpleButton;
      
      public var btn_3:SimpleButton;
      
      public var btn_4:SimpleButton;
      
      public var btn_5:SimpleButton;
      
      public var btn_6:SimpleButton;
      
      public var btnskill:SimpleButton;
      
      public var mc:MovieClip;
      
      public var mcastarlspirit_0:MovieClip;
      
      public var mcastarlspirit_1:MovieClip;
      
      public var mcastarlspirit_2:MovieClip;
      
      public var mcins_0:MovieClip;
      
      public var mcins_1:MovieClip;
      
      public var mcinsas:MovieClip;
      
      public var mcstudy:MovieClip;
      
      public var mequip_0:MovieClip;
      
      public var mequip_1:MovieClip;
      
      public var mequip_2:MovieClip;
      
      public var mequip_3:MovieClip;
      
      public var txtchara:TextField;
      
      public var txtgenius:TextField;
      
      public var txtlv:TextField;
      
      private var _pmSvr:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var _ieff:IPetBattleEffDataService = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
      
      private const TARGET_TABS:Array = [PetPackageTabs.TAB_LEVEL,PetPackageTabs.TAB_GEINUS,PetPackageTabs.TAB_STUDY,PetPackageTabs.TAB_PETCARD3,PetPackageTabs.TAB_INS,PetPackageTabs.TAB_CHARACTOR,PetPackageTabs.TAB_PET_INFOS];
      
      public function SimpleBar()
      {
         super();
         this.canUpdateUI = true;
         this.addEventListener(MouseEvent.CLICK,this.onClickAnywhere);
      }
      
      override protected function initUI() : void
      {
         this.refreshUI();
      }
      
      override protected function refreshUI() : void
      {
         var _loc1_:int = 0;
         var _loc4_:MovieClip = null;
         var _loc5_:EquipmentInfo = null;
         var _loc6_:MovieClip = null;
         var _loc7_:MovieClip = null;
         var _loc8_:UserAstralSpirit = null;
         var _loc9_:SimpleButton = null;
         if(this.pdi == null)
         {
            return;
         }
         this.txtlv.text = "LV." + pdi.level;
         this.txtgenius.text = GeniusHelper.getGeniusDesc(pdi.ind.arrayData);
         if(this._pmSvr.getOperationPM(pdi.raceId).pmData.isXinghuiPM())
         {
            this.mcstudy.visible = false;
         }
         else
         {
            this.mcstudy.visible = true;
            this.mcstudy.txtstudy.text = pdi.eff.total + "/" + PetPackageConfig.getMaxStudy();
         }
         this.txtchara.text = pdi.character;
         _loc1_ = 0;
         _loc1_ = 0;
         while(_loc1_ < 4)
         {
            _loc4_ = this.getChildByName("mequip_" + _loc1_) as MovieClip;
            _loc4_.visible = this.pdi.eqp != null && this.pdi.eqp[_loc1_] != null;
            if(_loc4_.visible)
            {
               _loc5_ = this.pdi.eqp[_loc1_];
               new MaterialContainer(_loc4_.m,"装备").setSingleView(MaterialTypes.PET_CARD,_loc5_.id,1,true,true);
            }
            _loc1_++;
         }
         (this.mcinsas as MovieClip).gotoAndStop(this._pmSvr.getOperationPM(pdi.raceId).pmData.isDegeneratorPM() ? 1 : 2);
         _loc1_ = 0;
         while(_loc1_ < 2)
         {
            _loc6_ = this.getChildByName("mcins_" + _loc1_) as MovieClip;
            _loc6_.visible = this.pdi.getInscriptionByType(_loc1_) > 0;
            if(_loc6_.visible)
            {
               new MaterialContainer(_loc6_,"铭文").setSingleView(MaterialTypes.INSCRIPTION,this.pdi.getInscriptionByType(_loc1_),1,true,true);
            }
            _loc1_++;
         }
         var _loc2_:IAstralSpiritService = ServiceContainer.getService(IAstralSpiritService) as IAstralSpiritService;
         var _loc3_:Array = this.pdi.astralSpiritUniqueIds;
         _loc1_ = 0;
         while(_loc1_ < AstralSpiritConfig.getTotalAstralSpiritPetCanEquip())
         {
            _loc7_ = this.getChildByName("mcastarlspirit_" + _loc1_) as MovieClip;
            if(_loc3_.length > _loc1_)
            {
               _loc8_ = _loc2_.getMyAstralSpiritByUniqueId(_loc3_[_loc1_]);
               _loc7_.visible = true;
               ActMaterialLoader.setView(_loc7_,MaterialTypes.ASTRAL_SPIRIT,_loc8_.materialId,true,null,_loc8_.level,{
                  "sv":_loc8_.strengthValue,
                  "levelObj":_loc8_.levelObj
               });
            }
            else
            {
               _loc7_.visible = false;
            }
            _loc1_++;
         }
         _loc1_ = 0;
         while(_loc1_ < 6)
         {
            _loc9_ = this.getChildByName("btn_" + _loc1_) as SimpleButton;
            _loc9_.visible = PetBattleDetectHelper.getDetectNumByType(_loc1_,this.pdi) < PetBattleDetectHelper.MaxNum[_loc1_];
            _loc1_++;
         }
         this.btn_6.visible = this._ieff.getPetBattleEffectiveness(this.pdi) < this._ieff.getPetMaxBattleEffectivenessByRaceId(this.pdi.raceId);
         ArtNumberManager.setNumber([this.mc.num_0,this.mc.num_1,this.mc.num_2,this.mc.num_3,this.mc.num_4],this._ieff.getPetBattleEffectiveness(this.pdi));
         this.btn_2.visible = !this._pmSvr.getOperationPM(pdi.raceId).pmData.isXinghuiPM();
      }
      
      private function onClickAnywhere(param1:MouseEvent) : void
      {
         var _loc3_:int = 0;
         PackageSkinManager.instance.changeClassify(Classify.NORMAL);
         var _loc2_:IPetPackageService = ServiceContainer.getService(IPetPackageService) as IPetPackageService;
         if(param1.target.name.indexOf("btn_") >= 0)
         {
            _loc3_ = int(param1.target.name.split("_")[1]);
            if(_loc3_ == 4 && Boolean(this._pmSvr.getOperationPM(pdi.raceId).pmData.isXinghuiPM()))
            {
               _loc2_.changeToTargetTab(PetPackageTabs.TAB_ASTARLSPIRIT);
            }
            else
            {
               _loc2_.changeToTargetTab(this.TARGET_TABS[_loc3_]);
            }
         }
         else if(param1.target.name == "btnskill")
         {
            _loc2_.changeToTargetTab(PetPackageTabs.TAB_PET_INFOS);
         }
         this.updateOnlyPanel();
      }
   }
}

