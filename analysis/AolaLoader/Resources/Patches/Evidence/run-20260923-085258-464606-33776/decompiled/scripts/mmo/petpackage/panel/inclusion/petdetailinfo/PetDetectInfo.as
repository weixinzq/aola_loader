package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.MaterialServiceEvent;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.astralspirit.AstralSpiritConfig;
   import mmo.interfaces.material.astralspirit.IAstralSpiritService;
   import mmo.interfaces.material.crystalkey.CrystalKeyConfig;
   import mmo.interfaces.material.crystalkey.ICrystalKeyService;
   import mmo.interfaces.material.hk.HKConfig;
   import mmo.interfaces.material.hk.HKData;
   import mmo.interfaces.material.hk.HKHelp;
   import mmo.interfaces.material.hk.HKIconOtherParam;
   import mmo.interfaces.material.hk.IHKService;
   import mmo.interfaces.material.inscription.IInscriptionService;
   import mmo.interfaces.material.petcard.PetCard;
   import mmo.interfaces.material.petcard2.IPetCard2Service;
   import mmo.interfaces.material.petcard3.IPetCard3Service;
   import mmo.interfaces.material.petcard3.PetCard3TipsHelper;
   import mmo.interfaces.material.petcard3.UserPetCard3;
   import mmo.interfaces.material.tote.IToteService;
   import mmo.interfaces.material.tote.ToteActiveData;
   import mmo.interfaces.material.tote.ToteConfig;
   import mmo.interfaces.material.tote.ToteData;
   import mmo.interfaces.material.tote.ToteHelp;
   import mmo.interfaces.material.tote.TotePbiData;
   import mmo.interfaces.material.tote.ToteTipsParam;
   import mmo.interfaces.material.tote.UserTote;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.EquipmentInfo;
   import mmo.interfaces.pet.data.EquippedAstralSpiritInfo;
   import mmo.interfaces.pet.data.GodCardInfo;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetCharacterMap;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.data.petbattleeff.PetBattleDetectHelper;
   import mmo.interfaces.pet.petcardoptimize.IPetCardOptimizeService;
   import mmo.interfaces.pet.petcommon.GeniusHelper;
   import mmo.interfaces.pet.petpackage.IPetPackageService;
   import mmo.interfaces.pet.petpackage.PetPackageTabs;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.controller.helper.TabJumpHelper;
   import mmo.petpackage.controller.skin.PackageSkinManager;
   import mmo.petpackage.controller.skin.constant.Classify;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.play.activity.helper.Pet_Helper;
   import mmo.play.activity.material.MaterialContainer;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActMaterialLoader;
   import mmo.play.actthings.pet.ActPetDataUpdateHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1227")]
   public class PetDetectInfo extends MovieClip implements IDispose
   {
      
      public var btn_0:SimpleButton;
      
      public var btn_1:SimpleButton;
      
      public var btn_2:SimpleButton;
      
      public var btn_3:SimpleButton;
      
      public var btn_4:SimpleButton;
      
      public var btn_5:SimpleButton;
      
      public var btn_6:SimpleButton;
      
      public var mcCrystalKey_0:MovieClip;
      
      public var mcCrystalKey_1:MovieClip;
      
      public var mcTote_0:MovieClip;
      
      public var mcTote_1:MovieClip;
      
      public var mc_0:MovieClip;
      
      public var mc_1:MovieClip;
      
      public var mc_2:MovieClip;
      
      public var mc_3:MovieClip;
      
      public var mc_4:MovieClip;
      
      public var mc_5:MovieClip;
      
      public var mcastralspirit_0:MovieClip;
      
      public var mcastralspirit_1:MovieClip;
      
      public var mcastralspirit_2:MovieClip;
      
      public var mcequipinscription_0:MovieClip;
      
      public var mcequipinscription_1:MovieClip;
      
      public var mcequipstate_0:MovieClip;
      
      public var mcequipstate_1:MovieClip;
      
      public var mcequipstate_2:MovieClip;
      
      public var mcequipstate_3:MovieClip;
      
      public var mcgeniusname:MovieClip;
      
      public var mcgodcard_0:MovieClip;
      
      public var mcgodcard_1:MovieClip;
      
      public var mchk_0:MovieClip;
      
      public var mchk_1:MovieClip;
      
      public var mchk_2:MovieClip;
      
      public var mchk_3:MovieClip;
      
      public var mchk_4:MovieClip;
      
      public var mcpetcardtwo:MovieClip;
      
      public var txt_2:TextField;
      
      public var txt_character:TextField;
      
      public var txt_level:TextField;
      
      private const typeNum:int = 6;
      
      private var _petDataS:IPetDataService;
      
      private var _petBriefInfo:PetBriefInfo;
      
      private var _petBattleEff:IPetBattleEffDataService;
      
      private var _pmS:IPMService;
      
      private var _inscriptionService:IInscriptionService;
      
      private var petcard2Service:IPetCard2Service;
      
      private var petDataService:IPetDataService;
      
      private var petCard3Service:IPetCard3Service;
      
      private const TARGET_TABS:Array = [PetPackageTabs.TAB_LEVEL,PetPackageTabs.TAB_GEINUS,PetPackageTabs.TAB_STUDY,PetPackageTabs.TAB_PETCARD3,PetPackageTabs.TAB_INS,PetPackageTabs.TAB_CHARACTOR,PetPackageTabs.TAB_PETCARD2,PetPackageTabs.TAB_ASTARLSPIRIT,PetPackageTabs.TAB_GODCARD,PetPackageTabs.TAB_HK];
      
      public function PetDetectInfo()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this._pmS = ServiceContainer.getService(IPMService) as IPMService;
         this._inscriptionService = ServiceContainer.getService(IInscriptionService) as IInscriptionService;
         this._petBattleEff = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
         this.petDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         PetPackageEventDispatcher.instance.addEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onSelectedData);
         this.petcard2Service = ServiceContainer.getService(IPetCard2Service) as IPetCard2Service;
         this.petcard2Service.addEventListener(MaterialServiceEvent.EVENT_MATERIAL_UPDATE,this.onDataChange);
         this.petDataService.addEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onViewSinglePM);
         this.petDataService.addEventListener(PetDataServiceEvent.SELECTE_CHAGNE,this.onSelectedChange);
         this.petCard3Service = ServiceContainer.getService(IPetCard3Service) as IPetCard3Service;
         SocketClient.instance.addEventListener("54e_46",this.onPetDetailChanged);
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this._petDataS = ServiceContainer.getService(IPetDataService) as IPetDataService;
      }
      
      private function onSelectedChange(param1:PetDataServiceEvent) : void
      {
         this.refresh();
      }
      
      private function onViewSinglePM(param1:PetDataServiceEvent) : void
      {
         var _loc2_:PetDetailedInfo = new PetDetailedInfo();
         _loc2_.parseInfo(param1.params.pm);
         if(this.petDataService.getSelectPetId() == _loc2_.id)
         {
            this._petBriefInfo = PetBriefInfo(_loc2_);
            this.refreshView();
         }
      }
      
      private function isGQPet() : Boolean
      {
         if(this._petBriefInfo == null)
         {
            return false;
         }
         return this._pmS.getOperationPM(this._petBriefInfo.raceId).pmData.isGQPM();
      }
      
      private function isUsingNewSkillGQPet() : Boolean
      {
         if(this._petBriefInfo == null)
         {
            return false;
         }
         return Boolean(this._pmS.getOperationPM(this._petBriefInfo.raceId).pmData.isGQPM()) && this._petBriefInfo.usingGQSkillType == 1;
      }
      
      private function isXinghuiPet() : Boolean
      {
         if(this._petBriefInfo == null)
         {
            return false;
         }
         return this._pmS.getOperationPM(this._petBriefInfo.raceId).pmData.isXinghuiPM();
      }
      
      private function isShenbinPet() : Boolean
      {
         if(this._petBriefInfo == null)
         {
            return false;
         }
         return XinghuiPetType.isShenbinPet(this._petBriefInfo.raceId);
      }
      
      private function isDegeneratorPet() : Boolean
      {
         if(this._petBriefInfo == null)
         {
            return false;
         }
         return this._pmS.getOperationPM(this._petBriefInfo.raceId).pmData.isDegeneratorPM();
      }
      
      private function isLegendPet() : Boolean
      {
         if(this._petBriefInfo == null)
         {
            return false;
         }
         return this._pmS.getOperationPM(this._petBriefInfo.raceId).pmData.isLegendPM();
      }
      
      private function onDataChange(param1:MaterialServiceEvent) : void
      {
         this.refresh();
      }
      
      private function refresh() : void
      {
         var _loc1_:PetDetailedInfo = this.petDataService.getPetDetailedInfoById(this.petDataService.getSelectPetId());
         this._petBriefInfo = PetBriefInfo(_loc1_);
         this.refreshView();
      }
      
      private function refreshView() : void
      {
         var _loc2_:int = 0;
         var _loc5_:* = false;
         var _loc6_:int = 0;
         var _loc7_:MovieClip = null;
         var _loc8_:TextField = null;
         var _loc9_:SimpleButton = null;
         var _loc1_:int = 1;
         if(this._petBriefInfo == null)
         {
            return;
         }
         if(this.isGQPet())
         {
            _loc5_ = this._petBriefInfo.usingGQSkillType == 1;
            _loc1_ = _loc5_ ? 7 : 6;
            this.gotoAndStop(_loc1_);
            this.setMyHK();
            this.setPetCarryItem();
            this.setCrystalKey();
         }
         else if(this.isXinghuiPet())
         {
            if(this.isShenbinPet())
            {
               this.gotoAndStop(5);
               this.setMyGodcardSpirits();
            }
            else
            {
               this.gotoAndStop(4);
               this.setRecommandAstralSpirits();
            }
         }
         else if(this.isDegeneratorPet())
         {
            this.gotoAndStop(3);
            this.setRecommandInscriptions();
         }
         else if(this.isLegendPet())
         {
            this.gotoAndStop(2);
         }
         else
         {
            this.gotoAndStop(1);
            this.setPetCard2();
         }
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < this.typeNum)
         {
            _loc2_ = int(PetBattleDetectHelper.getDetectNumByType(_loc4_,this._petBriefInfo));
            _loc6_ = int(PetBattleDetectHelper.MaxNum[_loc4_]);
            if(_loc4_ == 1)
            {
               _loc6_ = int(PetBattleDetectHelper.getTianFuMax(this._petBriefInfo.raceId));
            }
            if(this.isLegendPet() && _loc4_ == 4)
            {
               _loc2_ = int(this._petBriefInfo.legendSoulLv);
               _loc6_ = 3;
            }
            if(this.isXinghuiPet() && _loc4_ == 4)
            {
               if(this.isShenbinPet() && _loc4_ == 4)
               {
                  _loc6_ = 2 * 9;
               }
               else
               {
                  _loc6_ = 15;
               }
            }
            if(this.isGQPet() && _loc4_ == 4)
            {
               _loc2_ = int(HKHelp.getPbiHkBattle(this._petBriefInfo));
               _loc6_ = 5000;
            }
            _loc3_ += _loc2_;
            _loc7_ = this.getChildByName("mc_" + _loc4_.toString()) as MovieClip;
            if(_loc7_)
            {
               _loc7_.mc.gotoAndStop(Math.floor(_loc7_.mc.totalFrames * _loc2_ / _loc6_));
            }
            _loc8_ = this.getChildByName("txt_" + _loc4_.toString()) as TextField;
            if(_loc8_)
            {
               _loc8_.text = _loc2_.toString() + "/" + _loc6_.toString();
            }
            _loc9_ = this.getChildByName("btn_" + _loc4_.toString()) as SimpleButton;
            if(_loc9_)
            {
               _loc9_.visible = true;
            }
            _loc4_++;
         }
         ActComHelper.setTxtValue(this,"txt_level","" + this._petBriefInfo.level);
         this.refreshPetEquip();
         this.refreshGeniusUI();
         ActComHelper.setTxtValue(this,"txteff",this._pmS.customData.pmDataMap.getPM(this._petBriefInfo.raceId).pmRecommendatoryLearningAbility);
         ActComHelper.setTxtValue(this,"txtchara",this._pmS.customData.pmDataMap.getPM(this._petBriefInfo.raceId).pmRecommendatoryCharacter);
         ActComHelper.setTxtValue(this,"txt_character",PetCharacterMap.getPetCharacterMyDesc(this._petBriefInfo.character,this._petBriefInfo.character + "↑++++ ↓----"));
      }
      
      private function setPetCarryItem(param1:Sprite = null) : void
      {
         var _loc5_:TotePbiData = null;
         var _loc6_:* = false;
         var _loc7_:Sprite = null;
         var _loc8_:UserTote = null;
         var _loc9_:ToteData = null;
         var _loc10_:ToteActiveData = null;
         if(!this._petBriefInfo.usingGQSkillType)
         {
            return;
         }
         if(param1 == null)
         {
            param1 = this;
         }
         var _loc2_:IToteService = ServiceContainer.getService(IToteService) as IToteService;
         var _loc3_:Vector.<TotePbiData> = this._petBriefInfo.toteArr;
         var _loc4_:int = 0;
         while(_loc4_ < ToteConfig.TypeDesArr.length)
         {
            _loc5_ = _loc3_ == null || _loc4_ >= _loc3_.length ? null : _loc3_[_loc4_];
            _loc6_ = _loc5_ != null;
            _loc7_ = ActComHelper.getChildNode(param1,"mcTote_" + _loc4_ + ".mcView") as Sprite;
            _loc7_.visible = _loc6_;
            ActComHelper.setVisible(param1,"mcTote_" + _loc4_ + ".btnAddTote",!_loc6_);
            if(_loc6_)
            {
               _loc8_ = _loc2_.getMyToteById(_loc5_.ui);
               _loc9_ = _loc2_.getToteDataById(_loc8_.materialId);
               _loc10_ = ToteHelp.getActiveData(_loc8_,this._petBriefInfo);
               ActMaterialLoader.setView(_loc7_,MaterialTypes.Tote,_loc5_.id,true,null,new ToteTipsParam(_loc8_.randomsArr,_loc10_));
            }
            _loc4_++;
         }
      }
      
      private function isGQPetGenuisNotPerfect(param1:PetBriefInfo) : Boolean
      {
         var _loc2_:Array = null;
         if(Boolean(Pet_Helper.checkPetIsGQPet(param1.raceId)) && GeniusHelper.getGeniusFrameIndex(param1.ind.arrayData) == GeniusHelper.DENG_FENG_ZAO_JI)
         {
            _loc2_ = GeniusHelper.getGQPetRecommendGeniusIdxs2(param1.raceId);
            if(param1.ind.arrayData[_loc2_[0]] != GeniusHelper.MAX_ABILITY_GQ_PET)
            {
               return true;
            }
         }
         return false;
      }
      
      private function refreshGeniusUI() : void
      {
         var _loc2_:int = 0;
         if(this._petBriefInfo != null)
         {
            _loc2_ = int(GeniusHelper.getGeniusFrameIndex(this._petBriefInfo.ind.arrayData));
         }
         else
         {
            _loc2_ = 7;
         }
         var _loc1_:MovieClip = this.mcgeniusname;
         _loc1_.gotoAndStop(_loc2_);
      }
      
      private function setPetCard2() : void
      {
         var _loc2_:int = 0;
         var _loc1_:MovieClip = ActComHelper.getMc(this,"mcpetcardtwo");
         if(!this._petBriefInfo.hadPetcard2())
         {
            ActMaterialLoader.removeView(_loc1_);
            TipsManager.getInstance().replaceTips(_loc1_,"未镶嵌特性");
         }
         else
         {
            _loc2_ = int(this._petBriefInfo.scId);
            ActMaterialLoader.setView(_loc1_,MaterialTypes.PET_CARD2,_loc2_);
         }
      }
      
      private function refreshPetEquip() : void
      {
         var _loc3_:int = 0;
         var _loc4_:Boolean = false;
         var _loc5_:EquipmentInfo = null;
         var _loc6_:UserPetCard3 = null;
         var _loc7_:mmo.interfaces.material.petcard.PetCard = null;
         var _loc8_:Boolean = false;
         var _loc9_:IGameOptionService = null;
         var _loc1_:int = 0;
         var _loc2_:int = 4;
         _loc3_ = 0;
         while(_loc3_ < _loc2_)
         {
            ActComHelper.setMcFrame(this,"mcequipstate_" + _loc3_,2);
            TipsManager.getInstance().removeTips(ActComHelper.getChildNode(this,"mcequipstate_" + _loc3_) as MovieClip);
            _loc3_++;
         }
         _loc3_ = 0;
         while(_loc3_ < _loc2_)
         {
            _loc4_ = this._petBriefInfo != null && this._petBriefInfo.eqp != null && this._petBriefInfo.eqp[_loc3_] != null;
            if(_loc4_)
            {
               _loc5_ = this._petBriefInfo.eqp[_loc3_] as EquipmentInfo;
               _loc6_ = this.petCard3Service.getMyPetCard3BySerial(_loc5_.equipid);
               _loc7_ = _loc6_.material as mmo.interfaces.material.petcard.PetCard;
               ActComHelper.setMcFrame(this,"mcequipstate_" + _loc7_.type,1);
               _loc8_ = true;
               _loc9_ = ServiceContainer.getService(IGameOptionService) as IGameOptionService;
               if(_loc9_.isGQSimpleSkillView)
               {
                  _loc8_ = false;
               }
               TipsManager.getInstance().replaceComplexTips(ActComHelper.getChildNode(this,"mcequipstate_" + _loc7_.type) as MovieClip,PetCard3TipsHelper.getNameBySerial(_loc5_.equipid),PetCard3TipsHelper.getHtmlTipsBySerial(_loc5_.equipid,_loc8_,this._petBriefInfo.usingGQSkillType == 1));
               _loc1_++;
            }
            _loc3_++;
         }
      }
      
      private function setRecommandInscriptions() : void
      {
         var _loc3_:int = 0;
         var _loc4_:MovieClip = null;
         var _loc5_:String = null;
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         while(_loc2_ < 2)
         {
            _loc3_ = int(this._petBriefInfo.getInscriptionByType(_loc2_));
            _loc4_ = ActComHelper.getMc(this,"mcequipinscription_" + _loc2_);
            if(_loc3_ > 0)
            {
               _loc5_ = this._petBriefInfo.getInscriptionExtAtt(_loc2_);
               TipsManager.getInstance().removeTips(_loc4_);
               ActMaterialLoader.setViewByBn(_loc4_,{
                  "type":MaterialTypes.INSCRIPTION,
                  "ext":_loc5_,
                  "id":_loc3_
               });
               _loc1_++;
            }
            else
            {
               ActMaterialLoader.removeView(_loc4_);
               TipsManager.getInstance().replaceTips(_loc4_,"未镶嵌铭文");
            }
            _loc2_++;
         }
      }
      
      private function setRecommandAstralSpirits() : void
      {
         var _loc6_:MovieClip = null;
         var _loc7_:EquippedAstralSpiritInfo = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc1_:int = int(AstralSpiritConfig.getTotalAstralSpiritPetCanEquip());
         var _loc2_:IAstralSpiritService = ServiceContainer.getService(IAstralSpiritService) as IAstralSpiritService;
         var _loc3_:int = 0;
         var _loc4_:Array = this._petBriefInfo.equippedAstralSpiritInfos;
         var _loc5_:int = 0;
         while(_loc5_ < _loc1_)
         {
            _loc6_ = ActComHelper.getMc(this,"mcastralspirit_" + _loc5_);
            if(_loc4_.length > _loc5_)
            {
               _loc7_ = _loc4_[_loc5_];
               _loc8_ = int(_loc7_.astralSpiritId);
               _loc9_ = int(_loc7_.level);
               TipsManager.getInstance().removeTips(_loc6_);
               new MaterialContainer(_loc6_).setSingleView(MaterialTypes.ASTRAL_SPIRIT,_loc8_,_loc9_,true,false,null,_loc7_);
            }
            else
            {
               new MaterialContainer(_loc6_).setSingleView(MaterialTypes.ASTRAL_SPIRIT,0,0);
               TipsManager.getInstance().replaceTips(_loc6_,"未镶嵌星灵");
            }
            _loc5_++;
         }
      }
      
      private function setMyGodcardSpirits() : void
      {
         var _loc2_:MovieClip = null;
         var _loc4_:GodCardInfo = null;
         var _loc1_:Array = this._petBriefInfo.gc;
         var _loc3_:int = 0;
         while(_loc3_ < _loc1_.length)
         {
            _loc2_ = ActComHelper.getMc(this,"mcgodcard_" + _loc3_);
            _loc4_ = _loc1_[_loc3_] as GodCardInfo;
            if(null != _loc4_ && _loc4_.uniqueId > 0 && _loc4_.materialId > 0)
            {
               TipsManager.getInstance().removeTips(_loc2_);
               ActMaterialLoader.setView(_loc2_,MaterialTypes.GOD_CARD,_loc4_.materialId);
            }
            else
            {
               ActMaterialLoader.removeView(_loc2_);
               TipsManager.getInstance().replaceTips(_loc2_,"未装备神兵");
            }
            _loc3_++;
         }
      }
      
      private function setMyHK(param1:Sprite = null) : void
      {
         var _loc6_:MovieClip = null;
         var _loc7_:MovieClip = null;
         var _loc8_:MovieClip = null;
         var _loc11_:int = 0;
         if(param1 == null)
         {
            param1 = this;
         }
         var _loc2_:int = int(HKConfig.SlotMaxNum);
         var _loc3_:Array = this._petBriefInfo.getHKIdArr();
         var _loc4_:Array = this._petBriefInfo.getHKSlotLvArr();
         var _loc5_:IHKService = ServiceContainer.getService(IHKService) as IHKService;
         var _loc9_:HKData = null;
         var _loc10_:int = 0;
         while(_loc10_ < _loc2_)
         {
            _loc6_ = ActComHelper.getMc(param1,"mchk_" + _loc10_);
            _loc7_ = ActComHelper.getMc(_loc6_,"hkcolorbg");
            _loc8_ = ActComHelper.getMc(_loc6_,"hkslotlv");
            if(_loc3_[_loc10_] == 0 || _loc3_[_loc10_] == null)
            {
               _loc9_ = null;
               _loc7_.gotoAndStop(1);
               _loc8_.visible = false;
               _loc7_.gotoAndStop(1);
               TipsManager.getInstance().removeTips(_loc6_);
            }
            else
            {
               _loc11_ = _loc4_[_loc10_] ? int(_loc4_[_loc10_]) : 0;
               _loc9_ = _loc5_.getHKDataById(_loc3_[_loc10_]);
               _loc7_.gotoAndStop(_loc9_.color + 2);
               _loc8_.gotoAndStop(_loc11_ + 1);
               _loc8_.visible = true;
               TipsManager.getInstance().removeTips(_loc6_);
               TipsManager.getInstance().addMaterialTipsByTypeId(_loc6_,MaterialTypes.HK_SOURCE,_loc3_[_loc10_],0,true,9,9,null,new HKIconOtherParam(HKIconOtherParam.SIZE_SMALL,false,0,_loc4_[_loc10_]));
            }
            _loc10_++;
         }
      }
      
      private function setCrystalKey(param1:Sprite = null) : void
      {
         var _loc5_:* = false;
         var _loc6_:Sprite = null;
         if(!this._petBriefInfo.usingGQSkillType)
         {
            return;
         }
         if(param1 == null)
         {
            param1 = this;
         }
         var _loc2_:ICrystalKeyService = ServiceContainer.getService(ICrystalKeyService) as ICrystalKeyService;
         var _loc3_:Array = this._petBriefInfo.crystalKeyIdList;
         var _loc4_:int = 0;
         while(_loc4_ < CrystalKeyConfig.CAN_SET_KEY_NUM)
         {
            _loc5_ = _loc3_[_loc4_] > 0;
            _loc6_ = ActComHelper.getChildNode(param1,"mcCrystalKey_" + _loc4_ + ".mcView") as Sprite;
            _loc6_.visible = _loc5_;
            ActComHelper.setVisible(param1,"mcCrystalKey_" + _loc4_ + ".btnAddCrystalKey",!_loc5_);
            if(_loc5_)
            {
               ActMaterialLoader.setView(_loc6_,MaterialTypes.CRYSTAL_KEY,_loc3_[_loc4_]);
            }
            _loc4_++;
         }
      }
      
      private function onSelectedData(param1:PetPackageEvent) : void
      {
         this._petBriefInfo = PetBriefInfo(PetDetailDataMap.instance.getPetDetailInfo(param1.params.id));
         this.refreshView();
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnback")
         {
            this.visible = false;
         }
         else if(_loc2_.indexOf("btn_") != -1)
         {
            this.onClickAnywhere(param1);
         }
         else if(_loc2_ == "btnAddTote")
         {
            TabJumpHelper.changeFirstTab(2);
            TabJumpHelper.changeSecondTab(7);
         }
         else if(_loc2_ == "btnGoHK")
         {
            TabJumpHelper.changeFirstTab(2);
            TabJumpHelper.changeSecondTab(6);
         }
         else if(_loc2_ == "btnAddCrystalKey")
         {
            TabJumpHelper.changeFirstTab(2);
            TabJumpHelper.changeSecondTab(8);
         }
      }
      
      private function onClickAnywhere(param1:MouseEvent) : void
      {
         PackageSkinManager.instance.changeClassify(Classify.NORMAL);
         var _loc2_:IPetPackageService = ServiceContainer.getService(IPetPackageService) as IPetPackageService;
         if(param1.target.name.indexOf("btn_") >= 0)
         {
            if(this._petBriefInfo != null && int(param1.target.name.split("_")[1]) == 4)
            {
               if(this.isXinghuiPet())
               {
                  if(this.isShenbinPet())
                  {
                     _loc2_.changeToTargetTab(this.TARGET_TABS[8]);
                  }
                  else
                  {
                     _loc2_.changeToTargetTab(this.TARGET_TABS[7]);
                  }
               }
               else if(this.isGQPet())
               {
                  _loc2_.changeToTargetTab(this.TARGET_TABS[9]);
               }
            }
            else if(int(param1.target.name.split("_")[1]) == 3)
            {
               this.onClickEquipGo();
            }
            else if(int(param1.target.name.split("_")[1]) == 6)
            {
               _loc2_.changeToTargetTab(this.TARGET_TABS[10]);
            }
            else
            {
               _loc2_.changeToTargetTab(this.TARGET_TABS[int(param1.target.name.split("_")[1])]);
            }
         }
         else if(param1.target.name == "btnskill")
         {
            _loc2_.changeToTargetTab(PetPackageTabs.TAB_PET_INFOS);
         }
      }
      
      private function onClickEquipGo() : void
      {
         var ipc:IPetPackageService;
         var hasEquip:Boolean = false;
         var equip:EquipmentInfo = null;
         var card3:UserPetCard3 = null;
         var j:int = 0;
         var selectEquip:UserPetCard3 = null;
         var materialId:int = 0;
         var serialId:int = 0;
         var selectTab:int = 0;
         var hasNotMaxLv:Boolean = false;
         var lvUpEquip:UserPetCard3 = null;
         var identifyEquip:UserPetCard3 = null;
         var hasNotMaxHole:Boolean = false;
         var goIndex:int = -1;
         var i:int = 0;
         while(i < 4)
         {
            hasEquip = this._petBriefInfo != null && this._petBriefInfo.eqp != null && this._petBriefInfo.eqp[i] != null;
            if(!hasEquip)
            {
               goIndex = 0;
               break;
            }
            equip = this._petBriefInfo.eqp[i] as EquipmentInfo;
            card3 = this.petCard3Service.getMyPetCard3BySerial(equip.equipid);
            card3.getHoleExtInfoByIndex(0);
            if(card3.level < 3 && hasNotMaxLv == false)
            {
               hasNotMaxLv = true;
               lvUpEquip = card3;
            }
            else if(hasNotMaxHole == false)
            {
               j = 0;
               while(j < card3.holeNum)
               {
                  if(card3.getHoleExtInfoByIndex(j).isFull == false)
                  {
                     identifyEquip = card3;
                     hasNotMaxHole = true;
                     break;
                  }
                  j++;
               }
            }
            i++;
         }
         if(goIndex == -1 && hasNotMaxLv)
         {
            goIndex = 1;
         }
         else if(goIndex == -1 && hasNotMaxHole)
         {
            goIndex = 2;
         }
         else
         {
            goIndex = 0;
         }
         ipc = ServiceContainer.getService(IPetPackageService) as IPetPackageService;
         if(goIndex == 0)
         {
            ipc.changeToTargetTab(this.TARGET_TABS[3]);
         }
         else if(goIndex != -1)
         {
            selectEquip = goIndex == 1 ? lvUpEquip : identifyEquip;
            materialId = equip != null ? int(selectEquip.materialId) : 0;
            serialId = equip != null ? int(selectEquip.serial) : 0;
            selectTab = goIndex == 1 ? 0 : 4;
            if(selectTab == 4 && serialId == -1)
            {
               selectTab = 2;
            }
            ModalDialogManager.getInstance().clearAll();
            ProgressFullSprite.show();
            ServiceContainer.instance.tryGetService(IPetCardOptimizeService,function(param1:IPetCardOptimizeService, param2:Object):void
            {
               ProgressFullSprite.close();
               param1.showPanel();
               param1.changeFunctionTab(selectTab,_petBriefInfo.id,materialId,serialId);
            });
         }
      }
      
      private function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function onPetDetailChanged(param1:SocketClientEvent) : void
      {
         if(this._petBriefInfo != null)
         {
            ActPetDataUpdateHelper.getInstance().viewSinglePet(this._petBriefInfo.id);
         }
      }
      
      public function dispose() : void
      {
         PetPackageEventDispatcher.instance.removeEventListener(PetPackageEvent.PET_DETAIL_UPDATE,this.onSelectedData);
         SocketClient.instance.removeEventListener("54e_46",this.onPetDetailChanged);
         this.petcard2Service.removeEventListener(MaterialServiceEvent.EVENT_MATERIAL_UPDATE,this.onDataChange);
         this.petDataService.removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onViewSinglePM);
         this.petDataService.removeEventListener(PetDataServiceEvent.SELECTE_CHAGNE,this.onSelectedChange);
      }
   }
}

