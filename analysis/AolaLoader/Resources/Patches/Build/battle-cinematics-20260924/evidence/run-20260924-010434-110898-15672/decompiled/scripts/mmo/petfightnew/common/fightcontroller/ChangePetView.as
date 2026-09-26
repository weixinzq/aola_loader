package mmo.petfightnew.common.fightcontroller
{
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.MovieClip;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.callback.FunCallInfo;
   import mmo.interfaces.degenerator.DegeneratorPetType;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.AoYiConfig;
   import mmo.interfaces.pet.data.BargainPetConfig;
   import mmo.interfaces.pet.data.GQDengShenChangJieSkillParse;
   import mmo.interfaces.pet.data.GQJueXingSkillParse;
   import mmo.interfaces.pet.data.GQZhenLiFaDianSkillParse;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetChangeViewConfig;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMJiujiData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.DocPetFight;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class ChangePetView implements IDispose
   {
      
      private static var _instance:ChangePetView;
      
      private var fightPanel:FightPanel;
      
      private var _locaId:int;
      
      private var _beforeRaceId:int;
      
      private var _curPet:PetBriefInfo;
      
      private var _isFace:Boolean;
      
      private var _petContainer:MCPetContainer;
      
      private var _getPetEvent:PetFightEvent;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      public function ChangePetView()
      {
         super();
      }
      
      public static function get instance() : ChangePetView
      {
         if(_instance == null)
         {
            _instance = new ChangePetView();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function changeView(param1:Object) : void
      {
         FightController.instance.desc = param1.desc;
         this.fightPanel.refreshTxt(FightController.instance.desc + " 。");
         this.fightPanel.canStart = true;
         this.fightPanel.whoSwitch = 1;
         var _loc2_:int = int(param1.reqSId);
         var _loc3_:PlayerBattleInfo = new PlayerBattleInfo();
         _loc3_.parseInfo(param1);
         var _loc4_:PetBriefInfo = _loc3_.myPets[0] as PetBriefInfo;
         var _loc5_:PlayerBattleInfo = FightData.instance.playerInfo[_loc2_] as PlayerBattleInfo;
         var _loc6_:PetBriefInfo = _loc5_.myPets[0] as PetBriefInfo;
         this._beforeRaceId = _loc6_.raceId;
         _loc6_.updateInfo(_loc4_);
         _loc6_.setChangeViewRound(FightController.instance.turnCount);
         this.fightPanel.hidePetInfoMC(_loc5_.locaId);
         if(_loc3_.slotId == FightData.instance.myInfo.operatingPlayer.slotId && !FightController.instance.isReplay)
         {
            this.fightPanel.clearMyPetInfo();
         }
         this.switchPet(_loc5_.locaId,_loc6_);
      }
      
      private function switchPet(param1:int, param2:PetBriefInfo) : void
      {
         this._locaId = param1;
         this._curPet = param2;
         --this.fightPanel.petLoadeNum;
         if(FightData.instance.isMySide(param1))
         {
            this._isFace = false;
         }
         else
         {
            this._isFace = true;
         }
         this._petContainer = new MCPetContainer(param2,this._isFace,param1,this.fightPanel.layerEffect);
         this._petContainer.addEventListener(PetFightEvent.GOT_PET,this.onGotPet);
         this._petContainer.startLoad();
      }
      
      private function onGotPet(param1:PetFightEvent) : void
      {
         this._getPetEvent = param1;
         this._petContainer.removeEventListener(PetFightEvent.GOT_PET,this.onGotPet);
         if(this.fightPanel == null)
         {
            return;
         }
         if(DocPetFight.skipBattlePresentation)
         {
            var _loc2_:* = this.fightPanel.petMCList[this._locaId];
            this.onPetChange(_loc2_.parent.getChildIndex(_loc2_),_loc2_);
            this.onEffectMoviePlayed();
            return;
         }
         _loc2_ = this._curPet.raceId % 10000;
         if(XinghuiPetType.isShiflePro(this._pmSvr.getOperationPM(_loc2_).pmData.getXinghuiType()))
         {
            this.onTalkMoviePlayed();
         }
         else if(AoYiConfig.isAoYiPet(this._beforeRaceId))
         {
            this.getAoYiMovie();
         }
         else if(BargainPetConfig.getBargainIdByTargetId(_loc2_) == -1)
         {
            if(this._pmSvr.getOperationPM(_loc2_).pmData.getDegeneratorType() == DegeneratorPetType.JUE)
            {
               if(FightData.instance.isLowQuality)
               {
                  this.onTalkMoviePlayed();
               }
               else
               {
                  this.showDegeneratorMovie(this._curPet.raceId,this._isFace,new FunCallInfo(this.onTalkMoviePlayed));
               }
            }
            else if(this._pmSvr.getOperationPM(_loc2_).pmData.getXinghuiType() == XinghuiPetType.JUEXING)
            {
               if(FightData.instance.isLowQuality)
               {
                  this.onTalkMoviePlayed();
               }
               else
               {
                  this.showXinghuiJuexingBigMovie(this._curPet.raceId,this._isFace,new FunCallInfo(this.onTalkMoviePlayed));
               }
            }
            else if(Boolean(this._pmSvr.getOperationPM(_loc2_).pmData.isDegeneratorPM()) || Boolean(this._pmSvr.getOperationPM(_loc2_).pmData.isLegendPM()) || Boolean(this._pmSvr.getOperationPM(_loc2_).pmData.isXinghuiPM()) || Boolean(this._pmSvr.getOperationPM(_loc2_).pmData.isGQPM()))
            {
               this.onTalkMoviePlayed();
            }
            else
            {
               this.showTalkMovie(this._curPet.raceId,this._isFace,new FunCallInfo(this.onTalkMoviePlayed));
            }
         }
         else
         {
            this.getBargainMovie();
         }
      }
      
      private function loadRes(param1:String, param2:Function) : void
      {
         var url:String = param1;
         var callBack:Function = param2;
         ResScheduler.getRes(ResParams.createTempByDomain(url,function(param1:*, param2:ApplicationDomain = null):void
         {
            if(fightPanel != null)
            {
               callBack.apply(null,[param2]);
            }
         },ResDomain.decorate(FightData.instance.applicationDomain),""));
      }
      
      private function getAoYiMovie() : void
      {
         this.loadRes("petfightres/aoyires",this.showAoYiMovie);
      }
      
      private function showAoYiMovie(param1:ApplicationDomain) : void
      {
         var effectUpClass:Class;
         var effectDownClass:Class;
         var curMCPetContainer:MCPetContainer = null;
         var index:int = 0;
         var effectUp:MovieClip = null;
         var effectDown:MovieClip = null;
         var domain:ApplicationDomain = param1;
         if(this.fightPanel == null)
         {
            return;
         }
         curMCPetContainer = this.fightPanel.petMCList[this._locaId] as MCPetContainer;
         index = curMCPetContainer.parent.getChildIndex(curMCPetContainer);
         effectUpClass = domain.getDefinition("mmo.petfightnew.common.MCAoYiUp") as Class;
         effectUp = new effectUpClass() as MovieClip;
         effectUp.x = curMCPetContainer.x;
         effectUp.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effectUp,index + 1);
         effectUp.gotoAndPlay(1);
         effectDownClass = domain.getDefinition("mmo.petfightnew.common.MCAoYiDown") as Class;
         effectDown = new effectDownClass() as MovieClip;
         effectDown.x = curMCPetContainer.x;
         effectDown.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effectDown,index);
         DisplayUtil.setBrightHalf(this.fightPanel.layerBackground);
         effectDown.gotoAndPlay(1);
         FightMovieManager.instance.addMovie(effectDown);
         FightMovieManager.instance.addMovie(effectUp);
         effectUp.addFrameScript(11,function():void
         {
            onPetChange(index,curMCPetContainer);
         });
         effectUp.addFrameScript(effectUp.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(effectUp);
            FightMovieManager.instance.removeMovie(effectDown);
            DisplayUtil.stopAndRemove(effectUp);
            DisplayUtil.stopAndRemove(effectDown);
            DisplayUtil.clearFilters(fightPanel.layerBackground);
            onEffectMoviePlayed();
         });
      }
      
      private function onPetChange(param1:int, param2:MCPetContainer) : void
      {
         var tweenVars:TweenLiteVars;
         var tweenMax:TweenMax = null;
         var index:int = param1;
         var curMCPetContainer:MCPetContainer = param2;
         curMCPetContainer.dispose();
         DisplayUtil.stopAndRemove(curMCPetContainer);
         this._petContainer.x = curMCPetContainer.x;
         this._petContainer.y = curMCPetContainer.y;
         this.fightPanel.petMCList[this._locaId] = this._petContainer;
         this.fightPanel.layerPet.addChildAt(this._petContainer,index + 1);
         if(DocPetFight.skipBattlePresentation)
         {
            this._petContainer.scaleX = 1;
            this._petContainer.scaleY = 1;
            return;
         }
         this._petContainer.scaleX = 0;
         this._petContainer.scaleY = 0;
         tweenVars = new TweenLiteVars();
         tweenVars.prop("scaleX",1);
         tweenVars.prop("scaleY",1);
         tweenVars.useFrames(true);
         tweenVars.onComplete(function():void
         {
            FightTweenMaxManager.instance.removeTweenMax(tweenMax);
         });
         tweenMax = new TweenMax(this._petContainer,12,tweenVars);
         FightTweenMaxManager.instance.addTweenMax(tweenMax);
      }
      
      private function getBargainMovie() : void
      {
         this.loadRes("petfightres/bargainres",this.showBargainMovie);
      }
      
      private function showBargainMovie(param1:ApplicationDomain) : void
      {
         var mcBargain:MovieClip = null;
         var curMCPetContainer:MCPetContainer = null;
         var index:int = 0;
         var domain:ApplicationDomain = param1;
         var mcClass:Class = domain.getDefinition("mmo.petfightnew.common.MCBargain") as Class;
         mcBargain = new mcClass() as MovieClip;
         curMCPetContainer = this.fightPanel.petMCList[this._locaId] as MCPetContainer;
         index = curMCPetContainer.parent.getChildIndex(curMCPetContainer);
         this.fightPanel.layerPet.addChildAt(mcBargain,index + 1);
         mcBargain.x = curMCPetContainer.x;
         mcBargain.y = curMCPetContainer.y;
         DisplayUtil.setBrightHalf(this.fightPanel.layerBackground);
         FightMovieManager.instance.addMovie(mcBargain);
         mcBargain.addFrameScript(9,function():void
         {
            fightPanel.shake();
            onPetChange(index,curMCPetContainer);
         });
         mcBargain.addFrameScript(mcBargain.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(mcBargain);
            DisplayUtil.stopAndRemove(mcBargain);
            DisplayUtil.clearFilters(fightPanel.layerBackground);
            onEffectMoviePlayed();
         });
         mcBargain.gotoAndPlay(1);
      }
      
      private function onTalkMoviePlayed() : void
      {
         var gqPetType:int = 0;
         gqPetType = int(this._pmSvr.getOperationPM(this._curPet.raceId).pmData.getGQType());
         var gqDengShenChangJieSkillParse:GQDengShenChangJieSkillParse = GQDengShenChangJieSkillParse.getDengShenChangJieSkillParse(this._curPet.raceId);
         var gqZhenLiFaDianSkillParse:GQZhenLiFaDianSkillParse = GQZhenLiFaDianSkillParse.getZhenLiFaDianSkillParse(this._curPet.raceId);
         if(gqDengShenChangJieSkillParse && GQPetType.isDengShenChangJie(gqPetType) && gqDengShenChangJieSkillParse.changeViewId == this._curPet.raceId)
         {
            this.showDengShenChangJieAppearMovie(FightData.instance.applicationDomain,this._locaId,this._curPet,new FunCallInfo(this.onEffectMoviePlayed));
         }
         else if(gqZhenLiFaDianSkillParse && GQPetType.isZhenLiFaDian(gqPetType) && gqZhenLiFaDianSkillParse.changeViewId == this._curPet.raceId)
         {
            this.showZhenLiFaDianAppearMovie(FightData.instance.applicationDomain,this._locaId,this._curPet,new FunCallInfo(this.onEffectMoviePlayed));
         }
         else
         {
            this.loadRes("petfightres/changeviewres",function(param1:ApplicationDomain):void
            {
               var _loc2_:GQJueXingSkillParse = null;
               if(_pmSvr.getOperationPM(_curPet.raceId).pmData.getDegeneratorType() == DegeneratorPetType.JUE)
               {
                  showJueEffectMovie(param1,_locaId,_curPet,new FunCallInfo(onEffectMoviePlayed));
               }
               else if(_pmSvr.getOperationPM(_curPet.raceId).pmData.getDegeneratorType() == DegeneratorPetType.GUILI)
               {
                  showGuiliEffectMovie(param1,_locaId,_curPet,new FunCallInfo(onEffectMoviePlayed));
               }
               else if(_pmSvr.getOperationPM(_curPet.raceId).pmData.getDegeneratorType() == DegeneratorPetType.SHEN)
               {
                  showShenEffectMovie(param1,_locaId,_curPet,new FunCallInfo(onEffectMoviePlayed));
               }
               else if(_pmSvr.getOperationPM(_curPet.raceId).pmData.getXinghuiType() == XinghuiPetType.DOUBLEGOD)
               {
                  showXinghuiEffectMovie(param1,_locaId,_curPet,new FunCallInfo(onEffectMoviePlayed));
               }
               else if(XinghuiPetType.isShiflePro(_pmSvr.getOperationPM(_curPet.raceId).pmData.getXinghuiType()))
               {
                  showOnlyEffectMovie(param1,_locaId);
               }
               else if(GQPetType.isArmorBurst(gqPetType))
               {
                  showArmorBurstMovie(param1,_locaId,_curPet,new FunCallInfo(onEffectMoviePlayed));
               }
               else if(GQPetType.isYiRen(gqPetType))
               {
                  showYiRenMovie(param1,_locaId,_curPet,new FunCallInfo(onEffectMoviePlayed));
               }
               else if(GQPetType.isJuexing(_pmSvr.getOperationPM(_curPet.raceId).pmData.getGQType()))
               {
                  _loc2_ = GQJueXingSkillParse.getJueXingSkillParse(_curPet.raceId);
                  if(_loc2_.changeRaceIds.indexOf(_curPet.raceId) != -1)
                  {
                     showJuexingAppearMovie(param1,_locaId,_curPet,new FunCallInfo(onEffectMoviePlayed));
                  }
                  else
                  {
                     showEffectMovie(param1,_locaId,_curPet,new FunCallInfo(onEffectMoviePlayed));
                  }
               }
               else if(GQPetType.isJiuRiChongXian(gqPetType))
               {
                  showJiuRiShenAppearMovie(param1,_locaId,_curPet,new FunCallInfo(onEffectMoviePlayed));
               }
               else
               {
                  showEffectMovie(param1,_locaId,_curPet,new FunCallInfo(onEffectMoviePlayed));
               }
            });
         }
      }
      
      private function onEffectMoviePlayed() : void
      {
         if(this._locaId == FightData.instance.myInfo.operatingPlayer.locaId)
         {
            this.fightPanel.setFightClicked(true);
         }
         this.fightPanel.onGotPet(this._getPetEvent);
      }
      
      private function showEffectMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         var effectDownClass:Class;
         var curMCPetContainer:MCPetContainer = null;
         var index:int = 0;
         var effectUp:MovieClip = null;
         var effectDown:MovieClip = null;
         var domain:ApplicationDomain = param1;
         var locaId:int = param2;
         var curPet:PetBriefInfo = param3;
         var callBack:FunCallInfo = param4;
         curMCPetContainer = this.fightPanel.petMCList[locaId] as MCPetContainer;
         index = curMCPetContainer.parent.getChildIndex(curMCPetContainer);
         var effectUpClass:Class = domain.getDefinition("mmo.petfightnew.common.ChangeViewEffectUp") as Class;
         effectUp = new effectUpClass() as MovieClip;
         effectUp.x = curMCPetContainer.x;
         effectUp.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effectUp,index + 1);
         effectUp.gotoAndPlay(1);
         effectDownClass = domain.getDefinition("mmo.petfightnew.common.ChangeViewEffectDown") as Class;
         effectDown = new effectDownClass() as MovieClip;
         effectDown.x = curMCPetContainer.x;
         effectDown.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effectDown,index);
         DisplayUtil.setBrightHalf(this.fightPanel.layerBackground);
         effectDown.gotoAndPlay(1);
         FightMovieManager.instance.addMovie(effectDown);
         FightMovieManager.instance.addMovie(effectUp);
         effectUp.addFrameScript(13,function():void
         {
            DisplayUtil.stopAndRemove(curMCPetContainer);
            onPetChange(index,curMCPetContainer);
         });
         effectUp.addFrameScript(15,function():void
         {
            var _loc1_:IPMService = ServicePool.instance.getService(IPMService);
            if(!_loc1_.getOperationPM(_curPet.raceId).pmData.isDegeneratorPM())
            {
               showAbilityMovie(curPet,locaId);
            }
         });
         effectUp.addFrameScript(effectUp.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(effectDown);
            FightMovieManager.instance.removeMovie(effectUp);
            DisplayUtil.stopAndRemove(effectUp);
            DisplayUtil.stopAndRemove(effectDown);
            DisplayUtil.clearFilters(fightPanel.layerBackground);
            callBack.invoke();
         });
      }
      
      private function showJuexingAppearMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showJiuRiShenAppearMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showDengShenChangJieAppearMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showZhenLiFaDianAppearMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showJueEffectMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         var curMCPetContainer:MCPetContainer = null;
         var index:int = 0;
         var effect:MovieClip = null;
         var domain:ApplicationDomain = param1;
         var locaId:int = param2;
         var curPet:PetBriefInfo = param3;
         var callBack:FunCallInfo = param4;
         curMCPetContainer = this.fightPanel.petMCList[locaId] as MCPetContainer;
         index = curMCPetContainer.parent.getChildIndex(curMCPetContainer);
         var effectClass:Class = domain.getDefinition("mmo.petfightnew.common.DegeneratorJueChangeViewEffect") as Class;
         effect = new effectClass() as MovieClip;
         effect.x = curMCPetContainer.x;
         effect.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effect,index + 1);
         effect.gotoAndPlay(1);
         FightMovieManager.instance.addMovie(effect);
         effect.addFrameScript(7,function():void
         {
            DisplayUtil.stopAndRemove(curMCPetContainer);
            onPetChange(index,curMCPetContainer);
         });
         effect.addFrameScript(effect.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(effect);
            DisplayUtil.stopAndRemove(effect);
            DisplayUtil.clearFilters(fightPanel.layerBackground);
            callBack.invoke();
         });
      }
      
      private function showGuiliEffectMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         var curMCPetContainer:MCPetContainer = null;
         var index:int = 0;
         var effect:MovieClip = null;
         var domain:ApplicationDomain = param1;
         var locaId:int = param2;
         var curPet:PetBriefInfo = param3;
         var callBack:FunCallInfo = param4;
         curMCPetContainer = this.fightPanel.petMCList[locaId] as MCPetContainer;
         index = curMCPetContainer.parent.getChildIndex(curMCPetContainer);
         var effectClass:Class = domain.getDefinition("mmo.petfightnew.common.DegeneratorGuiliChangeViewEffect") as Class;
         effect = new effectClass() as MovieClip;
         effect.x = curMCPetContainer.x;
         effect.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effect,index + 1);
         effect.gotoAndPlay(1);
         FightMovieManager.instance.addMovie(effect);
         effect.addFrameScript(7,function():void
         {
            DisplayUtil.stopAndRemove(curMCPetContainer);
            onPetChange(index,curMCPetContainer);
         });
         effect.addFrameScript(effect.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(effect);
            DisplayUtil.stopAndRemove(effect);
            DisplayUtil.clearFilters(fightPanel.layerBackground);
            callBack.invoke();
         });
      }
      
      private function showShenEffectMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         var curMCPetContainer:MCPetContainer = null;
         var index:int = 0;
         var effect:MovieClip = null;
         var domain:ApplicationDomain = param1;
         var locaId:int = param2;
         var curPet:PetBriefInfo = param3;
         var callBack:FunCallInfo = param4;
         curMCPetContainer = this.fightPanel.petMCList[locaId] as MCPetContainer;
         index = curMCPetContainer.parent.getChildIndex(curMCPetContainer);
         var effectClass:Class = domain.getDefinition("mmo.petfightnew.common.DegeneratorShenChangeViewEffect") as Class;
         effect = new effectClass() as MovieClip;
         effect.x = curMCPetContainer.x;
         effect.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effect,index + 1);
         effect.gotoAndPlay(1);
         FightMovieManager.instance.addMovie(effect);
         effect.addFrameScript(7,function():void
         {
            DisplayUtil.stopAndRemove(curMCPetContainer);
            onPetChange(index,curMCPetContainer);
         });
         effect.addFrameScript(effect.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(effect);
            DisplayUtil.stopAndRemove(effect);
            DisplayUtil.clearFilters(fightPanel.layerBackground);
            callBack.invoke();
         });
      }
      
      private function showXinghuiEffectMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         var curMCPetContainer:MCPetContainer = null;
         var index:int = 0;
         var effect:MovieClip = null;
         var domain:ApplicationDomain = param1;
         var locaId:int = param2;
         var curPet:PetBriefInfo = param3;
         var callBack:FunCallInfo = param4;
         curMCPetContainer = this.fightPanel.petMCList[locaId] as MCPetContainer;
         index = curMCPetContainer.parent.getChildIndex(curMCPetContainer);
         var effectClass:Class = domain.getDefinition("mmo.petfightnew.common.XinghuiChangeViewEffect") as Class;
         effect = new effectClass() as MovieClip;
         effect.x = curMCPetContainer.x;
         effect.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effect,index + 1);
         effect.gotoAndPlay(1);
         FightMovieManager.instance.addMovie(effect);
         effect.addFrameScript(13,function():void
         {
            DisplayUtil.stopAndRemove(curMCPetContainer);
            onPetChange(index,curMCPetContainer);
         });
         effect.addFrameScript(effect.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(effect);
            DisplayUtil.stopAndRemove(effect);
            DisplayUtil.clearFilters(fightPanel.layerBackground);
            callBack.invoke();
         });
      }
      
      private function showAbilityMovie(param1:PetBriefInfo, param2:int) : void
      {
         var jiujiData:PMJiujiData = null;
         var mcAbility:MovieClip = null;
         var curMCPetContainer:MCPetContainer = null;
         var raceId:int = 0;
         var effectArr:Array = null;
         var count:int = 0;
         var i:int = 0;
         var mc:MovieClip = null;
         var effect:int = 0;
         var mc1:MovieClip = null;
         var petInfo:PetBriefInfo = param1;
         var locaId:int = param2;
         var pmService:IPMService = ServicePool.instance.getService(IPMService);
         if(petInfo != null)
         {
            jiujiData = pmService.customData.pmJiujiPMMap.getJiujiPMByRaceAndLevel(petInfo.raceId,petInfo.changeViewLevel);
            if(jiujiData != null)
            {
               mcAbility = new AbilityMovie() as MovieClip;
               curMCPetContainer = this.fightPanel.petMCList[locaId] as MCPetContainer;
               mcAbility.x = curMCPetContainer.x;
               mcAbility.y = curMCPetContainer.y;
               this.fightPanel.layerPet.addChild(mcAbility);
               raceId = int(jiujiData.sourceRaceId);
               effectArr = PetChangeViewConfig.getEffct(raceId,petInfo.changeViewLevel);
               count = 0;
               i = 0;
               while(i < effectArr.length)
               {
                  mc = mcAbility.getChildByName("mc" + i.toString()) as MovieClip;
                  if(mc != null)
                  {
                     mc.visible = false;
                     mc.gotoAndStop(1);
                     mc.mc.gotoAndStop(1);
                  }
                  effect = int(effectArr[i]);
                  if(effect != 0)
                  {
                     mc = mcAbility.getChildByName("mc" + count.toString()) as MovieClip;
                     if(mc != null)
                     {
                        mc.visible = true;
                        mc.gotoAndStop(i + 1);
                        mc1 = mc.getChildByName("mc") as MovieClip;
                        if(count == 0)
                        {
                           FightMovieManager.instance.addMovie(mc1);
                           mc1.addFrameScript(mc1.totalFrames - 1,function():void
                           {
                              FightMovieManager.instance.removeMovie(mc1);
                              mc1.stop();
                              DisplayUtil.stopAndRemove(mcAbility);
                           });
                        }
                        mc1.gotoAndPlay(1);
                        count++;
                     }
                  }
                  i++;
               }
            }
         }
      }
      
      private function showTalkMovie(param1:int, param2:Boolean, param3:FunCallInfo) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showXinghuiJuexingBigMovie(param1:int, param2:Boolean, param3:FunCallInfo) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showDegeneratorMovie(param1:int, param2:Boolean, param3:FunCallInfo) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ArrayIndexOutOfBoundsException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showOnlyEffectMovie(param1:ApplicationDomain, param2:int) : void
      {
         var effectDownClass:Class;
         var effectUp:MovieClip = null;
         var effectDown:MovieClip = null;
         var domain:ApplicationDomain = param1;
         var locaId:int = param2;
         var curMCPetContainer:MCPetContainer = this.fightPanel.petMCList[locaId] as MCPetContainer;
         var index:int = curMCPetContainer.parent.getChildIndex(curMCPetContainer);
         var effectUpClass:Class = domain.getDefinition("mmo.petfightnew.common.ChangeViewEffectUp") as Class;
         effectUp = new effectUpClass() as MovieClip;
         effectUp.x = curMCPetContainer.x;
         effectUp.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effectUp,index + 1);
         effectUp.gotoAndPlay(1);
         effectDownClass = domain.getDefinition("mmo.petfightnew.common.ChangeViewEffectDown") as Class;
         effectDown = new effectDownClass() as MovieClip;
         effectDown.x = curMCPetContainer.x;
         effectDown.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effectDown,index);
         effectDown.gotoAndPlay(1);
         FightMovieManager.instance.addMovie(effectDown);
         FightMovieManager.instance.addMovie(effectUp);
         effectUp.addFrameScript(15,function():void
         {
         });
         effectUp.addFrameScript(effectUp.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(effectDown);
            FightMovieManager.instance.removeMovie(effectUp);
            DisplayUtil.stopAndRemove(effectUp);
            DisplayUtil.stopAndRemove(effectDown);
            fightPanel.onGotPet(_getPetEvent);
         });
      }
      
      private function showArmorBurstMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showYiRenMovie(param1:ApplicationDomain, param2:int, param3:PetBriefInfo, param4:FunCallInfo) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ArrayIndexOutOfBoundsException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
   }
}

