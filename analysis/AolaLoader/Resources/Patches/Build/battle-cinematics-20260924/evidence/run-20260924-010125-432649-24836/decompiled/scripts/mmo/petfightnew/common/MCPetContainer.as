package mmo.petfightnew.common
{
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.FrameLabel;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.BitmapFilterQuality;
   import flash.filters.BlurFilter;
   import flash.filters.GlowFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.event.EnterFrameManager;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.degenerator.DegeneratorPetType;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.material.fightflauntresource.IFightFlauntResourceService;
   import mmo.interfaces.miraclepet.IMiraclePetDataService;
   import mmo.interfaces.miraclepet.MiraclePetInfo;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.GQYiweiShenggeSkillParse;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.data.skin.IPetSkinDataService;
   import mmo.interfaces.pet.data.skin.PetSkinInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMLegendBigSkillTypes;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.DocPetFight;
   import mmo.petfightnew.common.chat.TalkBubble;
   import mmo.petfightnew.common.effectmc.McAIPetAppear;
   import mmo.petfightnew.common.effectmc.McEffectBase;
   import mmo.petfightnew.common.effectmc.McMyPetAppear;
   import mmo.petfightnew.common.effectmc.McMyPetEscape;
   import mmo.petfightnew.common.effectmc.McMySwitch;
   import mmo.petfightnew.common.effectmc.McPetDie;
   import mmo.petfightnew.common.effectmc.McPetDie1;
   import mmo.petfightnew.common.effectmc.McVsPetAppear;
   import mmo.petfightnew.common.effectmc.McVsPetEscape;
   import mmo.petfightnew.common.effectmc.McVsSwitch;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.event.FightInnerEvent;
   import mmo.petfightnew.common.helper.CriticalMovieHelper;
   import mmo.petfightnew.common.manager.FightFrameRateManager;
   import mmo.petfightnew.common.manager.FightMcFactory;
   import mmo.petfightnew.common.manager.FightMcKeys;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   import mmo.petfightnew.common.manager.GQKillBigMovieLoader;
   import mmo.petfightnew.common.manager.PreloadListManager;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.manager.XingHuiKillBigMovieLoader;
   import mmo.petfightnew.common.movies.GQHurtMovie;
   import mmo.petfightnew.common.movies.HurtMovie;
   import mmo.petfightnew.common.movies.MyMark;
   import mmo.petfightnew.common.movies.SmokeMovie_Back;
   import mmo.petfightnew.common.movies.SmokeMovie_Positive;
   import mmo.petfightnew.common.movies.StopMovie;
   import mmo.petfightnew.common.panel.ChangeMouse;
   import mmo.petfightnew.common.pet.BitmapPetMovieStrategy;
   import mmo.petfightnew.common.pet.PetActionFrame;
   import mmo.petfightnew.common.pet.PetFace;
   import mmo.petfightnew.common.pet.PetMovieStrategyBase;
   import mmo.petfightnew.common.pet.VectorgraphPetMovieStrategy;
   import mmo.petfightnew.common.skilleffect.AnnualFee22EffEctCtrl;
   import mmo.petfightnew.common.skilleffect.GQGuangJinEffectHelper;
   import mmo.petfightnew.common.skilleffect.GQHuanLingShiEffectHelper;
   import mmo.petfightnew.common.skilleffect.GQShenBingEffectHelper;
   import mmo.petfightnew.common.skilleffect.GQTianYiEffectHelper;
   import mmo.petfightnew.common.skilleffect.GQYanhuaZhiyaoEffectHelper;
   import mmo.petfightnew.common.skilleffect.ShenLingEffEctCtrl;
   import mmo.petfightnew.common.ui.PetMouseResonder;
   import mmo.petfightnew.common.util.BitmapMovieHelper;
   import mmo.petfightnew.common.util.GQMingYunBoYiEffectHelper;
   import mmo.petfightnew.common.util.GQPetHelper;
   import mmo.petfightnew.common.util.MoveUtil;
   import mmo.petfightnew.common.util.PositionUtil;
   import mmo.petfightnew.common.util.ScreenShaker;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.petfightnew.common.util.TimerUtil;
   import mmo.play.petfight.common.PetMovieStrategyType;
   import mmo.play.petfight.common.config.FightResConfig;
   import mmo.play.petfight.common.config.GQKillBigConfig;
   import mmo.play.petfight.common.config.SkillMap;
   import mmo.play.player.talkable.ITalkable;
   import mmo.play.util.bitmapmovie.SyncBitmapMovieClip;
   
   public class MCPetContainer extends MovieClip implements ITalkable
   {
      
      public static const DefaultCTF:ColorTransform = new ColorTransform();
      
      public static const JueduiWeiduCTF:ColorTransform = new ColorTransform(1,1,1,0.95,93,187,229);
      
      public static const LiangziXinglianCTF:ColorTransform = new ColorTransform(1,1,1,0.95,93,187,229);
      
      public static const LingshouRealityCTF:ColorTransform = new ColorTransform(0.5,0,0.5,1,128,0,128);
      
      private var _petSkinDataSvr:IPetSkinDataService = ServicePool.instance.getService(IPetSkinDataService);
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var _ffrs:IFightFlauntResourceService = ServicePool.instance.getService(IFightFlauntResourceService);
      
      private var _skillMsgSvr:* = ServiceContainer.instance.getService(IPetSkillMesService) as IPetSkillMesService;
      
      private var raceId:int;
      
      public var flaId:int;
      
      private var isFace:Boolean;
      
      private var atk:Point;
      
      private var def:Point;
      
      private var slotId:int;
      
      private var _loacId:int;
      
      private var talkable:TalkBubble;
      
      private var _isDefending:Boolean = false;
      
      private var _isAttack:Boolean = false;
      
      private var onAttackEnd:Function;
      
      private var _setPetVisible:Function;
      
      private var skillId:int = -1;
      
      private var isCriticalHit:Boolean;
      
      private var _upLightBitmap:SyncBitmapMovieClip;
      
      private var _downLightBitmap:SyncBitmapMovieClip;
      
      private var stopMovie:MovieClip;
      
      private var _movieStrategy:PetMovieStrategyBase;
      
      private var _currentFrame:int;
      
      private var _currentActionMovie:MovieClip;
      
      private var _needSwitch:Boolean = false;
      
      private var isShowAppearEffect:Boolean;
      
      private var _mouseResponder:Sprite = null;
      
      private var _myMark:Sprite = null;
      
      private var _pbi:PetBriefInfo;
      
      private var _xingHuiKillBigMovieLoader:XingHuiKillBigMovieLoader;
      
      private var _gqKillBigMovieLoader:GQKillBigMovieLoader;
      
      private var _shenLingEffEctCtrl:ShenLingEffEctCtrl;
      
      private var _annualFee22EffEctCtrl:AnnualFee22EffEctCtrl;
      
      private var _gqGuangjinEffectHelper:GQGuangJinEffectHelper;
      
      private var _gqShenBingEffecthelper:GQShenBingEffectHelper;
      
      private var _gqTianyiEffectHelper:GQTianYiEffectHelper;
      
      private var _yanhuaZhiyaoEffectHelper:GQYanhuaZhiyaoEffectHelper;
      
      private var _mingYunBoYiEffectHelper:GQMingYunBoYiEffectHelper;
      
      private var _huanLingShiEffecthelper:GQHuanLingShiEffectHelper;
      
      private var _isLoading:Boolean = false;
      
      public function MCPetContainer(param1:PetBriefInfo, param2:Boolean, param3:int, param4:DisplayObjectContainer)
      {
         super();
         this._pbi = param1;
         this.raceId = param1.raceId;
         this.flaId = PetAssetsMap.getPetFlaId(param1.viewId);
         this.isFace = param2;
         this._loacId = param3;
         this.talkable = new TalkBubble(this,this.getScaleRate(),param2);
         this.addEventListener(MouseEvent.ROLL_OVER,this.onOverPet);
         this.addEventListener(MouseEvent.ROLL_OUT,this.onOutPet);
         this.addEventListener(Event.REMOVED_FROM_STAGE,this.onPetRemove);
         this.addEventListener(Event.ADDED_TO_STAGE,this.onAddedPet);
         if(XinghuiPetType.isShenLingGuard(this._pmSvr.customData.pmDataMap.getPM(this.raceId).getXinghuiType()))
         {
            this._shenLingEffEctCtrl = new ShenLingEffEctCtrl(this._pbi,this._loacId,this.isFace);
         }
         if(this._pbi.getXingHuiAnnualFee22SkillParser().isAnnualSummon)
         {
            this._annualFee22EffEctCtrl = new AnnualFee22EffEctCtrl(this._pbi,this._loacId,this.isFace);
         }
         if(GQPetType.isGuangJin(this._pmSvr.getOperationPM(this.raceId).pmData.getGQType()))
         {
            this._gqGuangjinEffectHelper = new GQGuangJinEffectHelper(this._pbi,this._loacId,this.isFace);
         }
         if(Boolean(this._pmSvr.getOperationPM(this.raceId).pmData.isGQPM()) && Boolean(this._pbi.isQiyueShenBing) && this.isGQShenbingZhufu())
         {
            this._gqShenBingEffecthelper = new GQShenBingEffectHelper(this._pbi,this._loacId,this.isFace);
         }
         this._gqTianyiEffectHelper = new GQTianYiEffectHelper(this._pbi,this._loacId,this.isFace);
         this._yanhuaZhiyaoEffectHelper = new GQYanhuaZhiyaoEffectHelper(this._pbi,this._loacId,this.isFace);
         if(GQPetType.isMingYunBoYi(this._pmSvr.getOperationPM(this.raceId).pmData.getGQType()))
         {
            this._mingYunBoYiEffectHelper = new GQMingYunBoYiEffectHelper(this._pbi,this._loacId,this.isFace);
         }
         if(GQPetType.isHuanLingShi(this._pmSvr.getOperationPM(this.raceId).pmData.getGQType()))
         {
            this._huanLingShiEffecthelper = new GQHuanLingShiEffectHelper(this._pbi,this._loacId,this.isFace);
         }
      }
      
      public function get isDefending() : Boolean
      {
         return this._isDefending;
      }
      
      private function isGQShenbingZhufu() : Boolean
      {
         var _loc2_:PMSkill = null;
         var _loc1_:int = 0;
         while(_loc1_ < this._pbi.skills.length)
         {
            _loc2_ = this._pmSvr.customData.pmSkillMap.getSkill(this._pbi.skills[_loc1_].id);
            if(_loc2_.getSkillType() == PMSkillTypes.GQ_SHENBING_PASSIVE)
            {
               return true;
            }
            _loc1_++;
         }
         return false;
      }
      
      private function getMovieStrategy(param1:int) : PetMovieStrategyBase
      {
         var _loc2_:int = PetFace.getFaceId(this.isFace);
         if(FightData.instance.getPetMovieStrategyType(param1) == PetMovieStrategyType.VECTORGRAPH)
         {
            return new VectorgraphPetMovieStrategy(param1,_loc2_);
         }
         return new BitmapPetMovieStrategy(param1,_loc2_);
      }
      
      private function onOverPet(param1:MouseEvent) : void
      {
         if(this._needSwitch)
         {
            return;
         }
         FightEventDispatcher.instance.dispatchEvent(new CommonEvent(FightInnerEvent.ON_MOUSE_OVER_PET,{"locaId":this.locaId}));
      }
      
      private function onOutPet(param1:MouseEvent) : void
      {
         FightEventDispatcher.instance.dispatchEvent(new CommonEvent(FightInnerEvent.ON_MOUSE_OUT_PET,{"locaId":this.locaId}));
      }
      
      private function onAddedPet(param1:Event) : void
      {
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAddedPet);
         this.addMouseResponder();
      }
      
      private function onPetRemove(param1:Event) : void
      {
         this.removeEventListener(Event.REMOVED_FROM_STAGE,this.onPetRemove);
         this.dispose();
         this.removeSysEffectCtrl();
      }
      
      private function disposeMouseTouchPetListener() : void
      {
         this.onOutPet(null);
         this.removeEventListener(MouseEvent.ROLL_OVER,this.onOverPet);
         this.removeEventListener(MouseEvent.ROLL_OUT,this.onOutPet);
      }
      
      public function disposeMouseResponder() : void
      {
         if(this._mouseResponder)
         {
            DisplayUtil.stopAndRemove(this._mouseResponder);
            this._mouseResponder.removeEventListener(MouseEvent.ROLL_OVER,this.onOverPet);
            this._mouseResponder.removeEventListener(MouseEvent.ROLL_OUT,this.onOutPet);
            this.onOutPet(null);
            this._mouseResponder = null;
         }
         this.removeSysEffectCtrl();
      }
      
      public function get locaId() : int
      {
         return this._loacId;
      }
      
      public function say(param1:String, param2:int = -1) : void
      {
         this.talkable.say(param1,param2);
      }
      
      public function smile(param1:int) : void
      {
      }
      
      public function startLoad(param1:Boolean = true) : void
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         PreloadListManager.instance.preloadResOfPet(this._pbi,this.locaId);
         this.isShowAppearEffect = param1;
         var _loc2_:int = FightData.instance.getSlotId(this._loacId);
         var _loc3_:PlayerBattleInfo = FightData.instance.playerInfo[_loc2_];
         if(_loc3_.lingshouRealitySlotId == -1)
         {
            _loc4_ = this.flaId;
         }
         else
         {
            _loc6_ = int(FightData.instance.getPlayerInfoBySlotId(_loc3_.lingshouRealitySlotId).myPets[0].raceId);
            _loc4_ = int(PetAssetsMap.getPetFlaId(_loc6_));
         }
         this._isLoading = true;
         this._movieStrategy = this.getMovieStrategy(_loc4_);
         this._movieStrategy.prepareRes(this.onResPrepared);
         if(this.hasXingHuiKillBigMovie())
         {
            _loc5_ = this.getXingHuiKillMovieId();
            XingHuiKillBigMovieLoader.preload(_loc5_,new ResDomain(FightData.instance.applicationDomain));
         }
         else if(this.hasGQKillBigMovie())
         {
            _loc5_ = this.getGQKillMovieId();
            GQKillBigMovieLoader.preload(_loc5_,new ResDomain(FightData.instance.applicationDomain));
         }
      }
      
      public function showDieEffect(param1:Function) : Boolean
      {
         var _loc7_:Object = null;
         var _loc8_:PlayerBattleInfo = null;
         var _loc9_:Object = null;
         var _loc10_:XML = null;
         var _loc11_:String = null;
         var _loc12_:Array = null;
         var _loc13_:Array = null;
         var _loc14_:int = 0;
         var _loc15_:int = 0;
         this._needSwitch = true;
         if(!this._currentActionMovie || !this.contains(this._currentActionMovie))
         {
            if(param1 != null)
            {
               param1.apply(null,[this._loacId]);
            }
            return false;
         }
         if(FightData.instance.myInfo.isMyControlLocalId(this._loacId))
         {
            FightController.instance.fightPanel.removeStopMovie(this._loacId);
         }
         var _loc2_:Object = {};
         var _loc3_:int = 0;
         while(_loc3_ < FightController.instance.pmmStatuses.length)
         {
            _loc7_ = FightController.instance.pmmStatuses[_loc3_];
            if((_loc7_.player as PlayerBattleInfo).slotId == FightData.instance.getSlotId(this._loacId))
            {
               _loc2_ = _loc7_.killList;
               break;
            }
            _loc3_++;
         }
         var _loc4_:int = 0;
         var _loc5_:String = "";
         if(_loc2_)
         {
            _loc8_ = FightData.instance.playerInfo[FightData.instance.getSlotId(this._loacId)];
            if(_loc8_)
            {
               for each(_loc9_ in _loc2_)
               {
                  if(_loc9_.id == _loc8_.myPets[0].id)
                  {
                     _loc5_ = _loc9_.cpcp ? _loc9_.cpcp : "";
                     break;
                  }
               }
               if(_loc5_.length > 0)
               {
                  _loc10_ = new XML(_loc5_);
                  _loc11_ = _loc10_.@sw;
                  if(_loc11_ != null && _loc11_.length != 0)
                  {
                     _loc12_ = _loc11_.split("#");
                     _loc4_ = parseInt(_loc12_[1]);
                  }
               }
            }
         }
         _loc4_ = _loc4_ <= 0 ? int(this._ffrs.getDefaultFightFlauntResArr()[1]) : _loc4_;
         var _loc6_:String = FightData.instance.curBs;
         if(_loc6_.indexOf("ext=LYSC26061") >= 0)
         {
            _loc13_ = _loc6_.split("_");
            _loc14_ = parseInt(_loc13_[2]);
            _loc15_ = FightData.instance.getLocaId(_loc14_);
            if(_loc15_ == this._loacId)
            {
               new McPetDie1(this.raceId,this._loacId,this._currentActionMovie,param1,_loc4_,this,this.removeMiracleLight);
               return true;
            }
         }
         new McPetDie(this.raceId,this._loacId,this._currentActionMovie,param1,_loc4_,this,this.removeMiracleLight);
         return true;
      }
      
      public function showEscapeEffect(param1:Function) : void
      {
         var _loc3_:McEffectBase = null;
         this._needSwitch = true;
         if(!this._currentActionMovie || !this.contains(this._currentActionMovie))
         {
            if(param1 != null)
            {
               param1.apply(null,[this._loacId]);
            }
            return;
         }
         if(Boolean(this._pbi) && StatusUtil.getIsXianJingJiPet(this._pbi))
         {
            if(param1 != null)
            {
               param1.apply(null,[this._loacId]);
            }
            return;
         }
         var _loc2_:Boolean = FightData.instance.isMySide(this._loacId);
         if(_loc2_)
         {
            _loc3_ = new McMyPetEscape(this.raceId,this._loacId,this._currentActionMovie,param1);
         }
         else
         {
            _loc3_ = new McVsPetEscape(this.raceId,this._loacId,this._currentActionMovie,param1);
         }
         _loc3_.play();
         this.addChildAt(_loc3_,0);
         this.removeMiracleLight();
      }
      
      public function showSwitchEffect(param1:Function) : void
      {
         var _loc3_:McEffectBase = null;
         this._needSwitch = true;
         var _loc2_:Boolean = FightData.instance.isMySide(this._loacId);
         if(_loc2_)
         {
            _loc3_ = new McMySwitch(this.raceId,this._loacId,this._currentActionMovie,param1);
         }
         else
         {
            _loc3_ = new McVsSwitch(this.raceId,this._loacId,this._currentActionMovie,param1);
         }
         if(Boolean(_loc3_) && Boolean(_loc3_.mcEffect))
         {
            _loc3_.play();
            this.addChildAt(_loc3_,0);
         }
      }
      
      public function showSkillName(param1:String) : void
      {
         var point:Point;
         var h:Number;
         var mcSkillName:MovieClip = null;
         var skillName:String = param1;
         mcSkillName = FightMcFactory.getFightMcByKey(FightMcKeys.McSkillName);
         var txtSkill:TextField = mcSkillName["mc"]["txtSkill"] as TextField;
         txtSkill.text = skillName;
         point = PositionUtil.getDefaultPosition(this._loacId);
         mcSkillName.x = point.x;
         h = this._currentActionMovie == null ? this.height : this._currentActionMovie.height;
         mcSkillName.y = point.y - h - 10;
         mcSkillName.y = mcSkillName.y < 50 ? 50 : mcSkillName.y;
         FightMovieManager.instance.addMovie(mcSkillName);
         mcSkillName.addFrameScript(mcSkillName.totalFrames - 1,function():*
         {
            FightMovieManager.instance.removeMovie(mcSkillName);
            FightMcPool.removeMc(mcSkillName);
            FightMcPool.instance.pushMcByKey(FightMcKeys.McSkillName,mcSkillName);
         });
         mcSkillName.gotoAndPlay(1);
         FightController.instance.fightPanel.layerPet.addChild(mcSkillName);
      }
      
      private function onResPrepared() : void
      {
         this._isLoading = false;
         var _loc1_:int = FightData.instance.getSlotId(this._loacId);
         var _loc2_:PlayerBattleInfo = FightData.instance.playerInfo[_loc1_];
         this.annualSummonPetHandle(_loc2_);
         this.setNormal();
         if(FightData.instance.fightNum > 2 && !FightData.instance.isMultiControl() && !FightController.instance.isReplay)
         {
            if(FightData.instance.myInfo.isMyControlLocalId(this._loacId))
            {
               this.showMyMark();
            }
         }
         this.setMiracleLight();
         if(this.isShowAppearEffect)
         {
            this.showAppearEffect();
         }
         else
         {
            this.dispatchGotPet(this.locaId);
         }
      }
      
      private function annualSummonPetHandle(param1:PlayerBattleInfo) : void
      {
      }
      
      public function showMyMark() : void
      {
         var _loc1_:int = 0;
         if(this._myMark == null)
         {
            this._myMark = new MyMark();
            this._myMark.y += 20;
            _loc1_ = this.numChildren > 1 ? this.numChildren - 1 : 0;
            this.addChildAt(this._myMark,_loc1_);
         }
         this._myMark.visible = true;
      }
      
      public function hideMyMark() : void
      {
         if(this._myMark)
         {
            this._myMark.visible = false;
         }
      }
      
      private function addMouseResponder() : void
      {
         if(this._mouseResponder != null)
         {
            return;
         }
         this._mouseResponder = new PetMouseResonder();
         this._mouseResponder.mouseChildren = false;
         this._mouseResponder.x = this.x;
         this._mouseResponder.y = this.y;
         var _loc1_:MovieClip = FightController.instance.fightPanel.layerUI.getChildByName("mcPetMouseResonder") as MovieClip;
         _loc1_.addChild(this._mouseResponder);
         this._mouseResponder.addEventListener(MouseEvent.ROLL_OVER,this.onOverPet);
         this._mouseResponder.addEventListener(MouseEvent.ROLL_OUT,this.onOutPet);
      }
      
      private function setMiracleLight() : void
      {
         var service:IMiraclePetDataService;
         var upLight:MovieClip;
         var downLight:MovieClip;
         var info:MiraclePetInfo = null;
         this.removeMiracleLight();
         if(FightData.instance.isLowQuality)
         {
            return;
         }
         service = ServicePool.instance.getService(IMiraclePetDataService);
         info = service.getMiraclePetInfo(this.raceId);
         if(info == null)
         {
            return;
         }
         upLight = null;
         downLight = null;
         ResScheduler.getRes(ResParams.createTempByDomain("petfightres/miracleres",function(param1:MovieClip, param2:ApplicationDomain = null):void
         {
            _upLightBitmap = getBitmapMovieByClsName("mmo.petfightnew.MiracleUpLight_" + info.breakLevel);
            _downLightBitmap = getBitmapMovieByClsName("mmo.petfightnew.MiracleDownLight_" + info.breakLevel);
            addChildAt(_downLightBitmap,0);
            addChild(_upLightBitmap);
         },ResDomain.decorate(FightData.instance.applicationDomain),""));
      }
      
      private function getBitmapMovieByClsName(param1:String) : SyncBitmapMovieClip
      {
         var _loc2_:Class = FightData.instance.applicationDomain.getDefinition(param1) as Class;
         var _loc3_:MovieClip = new _loc2_() as MovieClip;
         return this.toSyncBitmapMovie(_loc3_);
      }
      
      private function toSyncBitmapMovie(param1:MovieClip) : SyncBitmapMovieClip
      {
         return BitmapMovieHelper.toSyncBitmapMovie(param1);
      }
      
      private function removeMiracleLight() : void
      {
         if(this._upLightBitmap)
         {
            this._upLightBitmap.dispose();
         }
         if(this._downLightBitmap)
         {
            this._downLightBitmap.dispose();
         }
      }
      
      override public function addChild(param1:DisplayObject) : DisplayObject
      {
         var _loc2_:DisplayObject = super.addChild(param1);
         if(this._upLightBitmap)
         {
            super.addChild(this._upLightBitmap);
         }
         return _loc2_;
      }
      
      private function dispatchGotPet(param1:int) : void
      {
         this.dispatchEvent(new PetFightEvent(PetFightEvent.GOT_PET,{"locaId":param1}));
      }
      
      private function showAppearEffect() : void
      {
         var actionMovie:MovieClip = null;
         var effectMc:McEffectBase = null;
         var thisObj:MCPetContainer = null;
         var isSummoned:Boolean = false;
         var bs1:String = null;
         var arr:Array = null;
         var slotId1:int = 0;
         var locaId1:int = 0;
         var slotId:int = FightData.instance.getSlotId(this._loacId);
         var player:PlayerBattleInfo = FightData.instance.playerInfo[slotId];
         if(player == null)
         {
            return;
         }
         if(Boolean(this._pbi) && StatusUtil.getIsXianJingJiPet(this._pbi))
         {
            this.dispatchGotPet(this._loacId);
            return;
         }
         if(player.PMMasterId < 0 && Boolean(this._movieStrategy))
         {
            actionMovie = this._movieStrategy.getActionMovie(PetActionFrame.FRAME_APPEAR);
            if(actionMovie != null)
            {
               this.playAction(PetActionFrame.FRAME_APPEAR);
               thisObj = this;
               FightMovieManager.instance.addMovie(this._currentActionMovie);
               this._currentActionMovie.addFrameScript(this._currentActionMovie.totalFrames - 1,function():void
               {
                  this._isLoading = false;
                  var _loc1_:int = FightData.instance.getSlotId(this._loacId);
                  var _loc2_:PlayerBattleInfo = FightData.instance.playerInfo[_loc1_];
                  this.annualSummonPetHandle(_loc2_);
                  this.setNormal();
                  if(FightData.instance.fightNum > 2 && !FightData.instance.isMultiControl() && !FightController.instance.isReplay)
                  {
                     if(FightData.instance.myInfo.isMyControlLocalId(this._loacId))
                     {
                        this.showMyMark();
                     }
                  }
                  this.setMiracleLight();
                  if(DocPetFight.skipBattlePresentation)
                  {
                     this.dispatchGotPet(this.locaId);
                     return;
                  }
                  if(this.isShowAppearEffect)
                  {
                     this.showAppearEffect();
                  }
                  else
                  {
                     this.dispatchGotPet(this.locaId);
                  }
               });
               this._currentActionMovie.gotoAndPlay(1);
               return;
            }
         }
         if(this._pmSvr.getOperationPM(this.flaId).pmData.getDegeneratorType() == DegeneratorPetType.XIAN && Boolean(this._movieStrategy))
         {
            actionMovie = this._movieStrategy.getActionMovie(PetActionFrame.FRAME_DEGENERATOR_XIAN_APPEAR);
            if(actionMovie != null)
            {
               this.playAction(PetActionFrame.FRAME_DEGENERATOR_XIAN_APPEAR);
               thisObj = this;
               FightMovieManager.instance.addMovie(this._currentActionMovie);
               this._currentActionMovie.addFrameScript(this._currentActionMovie.totalFrames - 1,function():*
               {
                  FightMovieManager.instance.removeMovie(_currentActionMovie);
                  thisObj._currentActionMovie.stop();
                  thisObj.setNormal();
                  thisObj.dispatchGotPet(_loacId);
                  if(FightData.instance.myInfo.isMyControlLocalId(this._loacId))
                  {
                     EnterFrameManager.instance.registerNextFrame(function():void
                     {
                        CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("my_degeneratorxian_pet_appear",null));
                     });
                  }
               });
               this._currentActionMovie.gotoAndPlay(1);
               return;
            }
         }
         if(player.PMMasterId < 0)
         {
            isSummoned = FightData.instance.isSummonedPlayer(player);
            effectMc = new McAIPetAppear(this.raceId,this._loacId,this._currentActionMovie,this.dispatchGotPet,isSummoned);
            if(effectMc)
            {
               this.addChildAt(effectMc,0);
               effectMc.play();
            }
            else
            {
               this.dispatchGotPet(this._loacId);
            }
         }
         else if(FightData.instance.isMySide(player.locaId))
         {
            new McMyPetAppear(this.raceId,this._loacId,this._currentActionMovie,this.dispatchGotPet,this._pbi,this);
         }
         else
         {
            bs1 = FightData.instance.curBs;
            if(bs1.indexOf("ext=LYSC26061") >= 0)
            {
               arr = bs1.split("_");
               slotId1 = parseInt(arr[1]);
               locaId1 = FightData.instance.getLocaId(slotId1);
               if(locaId1 == this._loacId)
               {
                  CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("mmo.activity260612.luyisitiaozhan26_xueji_movie",{}));
               }
            }
            new McVsPetAppear(this.raceId,this._loacId,this._currentActionMovie,this.dispatchGotPet,this._pbi,this);
         }
         this.showYingjiemengyueAppearMovie();
      }
      
      private function showYingjiemengyueAppearMovie() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:String = null;
         var _loc5_:String = null;
         if(StatusUtil.getIsInBuxiugonglingState(this._pbi))
         {
            _loc1_ = this._pmSvr.getOperationPM(this._pbi.raceId).getMaxCommonEvlution().raceId;
            _loc2_ = int(PetAssetsMap.getPetFlaId(_loc1_));
            _loc3_ = this.isFace ? 0 : 1;
            _loc4_ = "gqpet/yingjiemengyue/effect/yingjiemengyueeffect_" + _loc2_;
            _loc5_ = "mmo.gqpet.yingjiemengyue.effect.YingjiemengyueAppearEffect_" + _loc2_ + "_" + _loc3_;
            this.playAnimation(_loc4_,_loc5_);
         }
      }
      
      private function playAnimation(param1:String, param2:String, param3:Boolean = false, param4:Function = null) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      public function setNormal() : void
      {
         DocPetFight.noteDiagnosticAttackEnded(this);
         if(this.onAttackEnd != null)
         {
            this.onAttackEnd.apply();
            this.onAttackEnd = null;
         }
         FightFrameRateManager.instance.correctFrameRate();
         this.setPetColorTransform();
         this.playAction(PetActionFrame.FRAME_STAND);
         this._isDefending = false;
         this._isAttack = false;
      }
      
      public function setPetColorTransform() : void
      {
         var _loc3_:PetBriefInfo = null;
         var _loc1_:int = FightData.instance.getSlotId(this._loacId);
         var _loc2_:PlayerBattleInfo = FightData.instance.playerInfo[_loc1_];
         if(_loc2_)
         {
            _loc3_ = _loc2_.myPets[0];
            if(_loc3_)
            {
               this._pbi = _loc3_;
               if(_loc2_.lingshouRealitySlotId != -1)
               {
                  this.setColorTransform(LingshouRealityCTF);
               }
               else if(StatusUtil.getIsInLockByJueduiWeiduState(_loc3_))
               {
                  this.setColorTransform(JueduiWeiduCTF);
               }
               else if(StatusUtil.getIsInLiangziXinglianState(_loc3_))
               {
                  this.setColorTransform(LiangziXinglianCTF);
               }
               else
               {
                  this.setColorTransform(MCPetContainer.DefaultCTF);
               }
            }
         }
      }
      
      public function setColorTransform(param1:ColorTransform) : void
      {
         transform.colorTransform = param1;
      }
      
      public function attack(param1:int, param2:Point, param3:Point, param4:Boolean, param5:Boolean, param6:Function, param7:Function) : void
      {
         this._isDefending = false;
         this._isAttack = true;
         this.onAttackEnd = param6;
         DocPetFight.noteDiagnosticAttackStarted(this,param1,this._movieStrategy == null);
         if(this._movieStrategy == null)
         {
            return;
         }
         this.atk = param2;
         this.def = param3;
         this.onAttackEnd = param6;
         this._setPetVisible = param7;
         this.skillId = param1;
         this.isCriticalHit = param4;
         var _loc8_:int = int(SkillMap.instance.getAttFrame(param1));
         if(this.isLegendKillBigSkill(param1) || this.isDegeneratorBigSkill(param1) || this.isXinghuiKillBigSkill(param1) || this.isGQKillBigSkill(param1))
         {
            _loc8_ = PetActionFrame.FRAME_LEGEND_BIG;
         }
         else if(_loc8_ == PetActionFrame.FRAME_SPECIAL_ATT)
         {
            _loc8_ = PetActionFrame.FRAME_PHRYSICAL_ATT;
         }
         else if(_loc8_ == PetActionFrame.FRAME_ATTRIBUTE_ATT_OLD)
         {
            _loc8_ = PetActionFrame.FRAME_ATTRIBUTE_ATT;
         }
         var _loc9_:PMSkill = this._pmSvr.customData.pmSkillMap.getSkill(param1);
         var _loc10_:PetSkinInfo = this._petSkinDataSvr.getPetSkinInfoBySkinId(this.flaId);
         if(this.isGQKillBigSkill(param1) && _loc9_.attackType == 2)
         {
            _loc8_ = PetActionFrame.FRAME_ATTRIBUTE_ATT;
         }
         if((_loc10_ == null || Boolean(_loc10_.isNormalPet)) && (_loc9_.getSkillType() == PMSkillTypes.GQ_YINGHUN_EXTRA_SKILL && Boolean(GQPetType.getIsYingHunHas10thFrame(this.flaId))))
         {
            _loc8_ = PetActionFrame.FRAME_DEGENERATOR_XIAN_APPEAR;
         }
         else if(_loc10_ != null && FightResConfig.HaveTheirOwnCriticalMovieIdArr.indexOf(this.flaId) != -1)
         {
            if(this.isGQKillBigSkill(param1))
            {
               _loc8_ = PetActionFrame.FRAME_LEGEND_BIG;
            }
            else if(_loc9_.newSkillType == 2)
            {
               _loc8_ = PetActionFrame.FRAME_ZHUANGSHU_ATT;
            }
         }
         if(this._gqShenBingEffecthelper)
         {
            if(_loc9_.attackType != 2)
            {
               this._gqShenBingEffecthelper.attack(param2,param3);
            }
         }
         this.playAction(_loc8_);
      }
      
      private function isLegendKillBigSkill(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         return _loc2_.customData.pmSkillMap.getSkill(param1).getLegendBigSkillType() == PMLegendBigSkillTypes.LEGEND_KILL_BIG;
      }
      
      private function isDegeneratorBigSkill(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:int = int(_loc2_.customData.pmSkillMap.getSkill(param1).getSkillType());
         return _loc3_ == PMSkillTypes.DEGENERATOR_KILL_BIG || _loc3_ == PMSkillTypes.DEGENERATOR_SUPER_SPIRIT_PO || _loc3_ == PMSkillTypes.DEGENERATOR_YU_KILL_BIG || _loc3_ == PMSkillTypes.DEGENERATOR_SHENQI_KILL_BIG;
      }
      
      private function isXinghuiKillBigSkill(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:int = int(_loc2_.customData.pmSkillMap.getSkill(param1).getSkillType());
         return Boolean(PMSkillTypes.isXinghuiKillBig(_loc3_)) || Boolean(PMSkillTypes.isXinghuiSuperSpiritSkill(_loc3_));
      }
      
      private function isGQKillBigSkill(param1:int) : Boolean
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:int = int(_loc2_.customData.pmSkillMap.getSkill(param1).getSkillType());
         return PMSkillTypes.isGQKillBig(_loc3_);
      }
      
      private function showCriticalMovie(param1:int) : void
      {
         var thisObj:MCPetContainer = null;
         var frame:int = param1;
         thisObj = this;
         var criHitEnd:Function = function():void
         {
            thisObj.playAction(frame);
         };
         this.playAction(PetActionFrame.FRAME_CRI_HIT);
         if(this._currentActionMovie == null)
         {
            criHitEnd.apply();
         }
         else
         {
            FightMovieManager.instance.addMovie(this._currentActionMovie);
            this._currentActionMovie.addFrameScript(this._currentActionMovie.totalFrames - 1,criHitEnd);
            this._currentActionMovie.gotoAndPlay(1);
         }
      }
      
      private function onEnterAttFrame() : void
      {
         this.setPetMc(this._currentActionMovie);
      }
      
      private function getColorMatrix(param1:int, param2:int) : Array
      {
         var _loc3_:Number = param1 / 100;
         return [0.3086 * (1 - _loc3_) + _loc3_,0.6094 * (1 - _loc3_),0.082 * (1 - _loc3_),0,param2,0.3086 * (1 - _loc3_),0.6094 * (1 - _loc3_) + _loc3_,0.082 * (1 - _loc3_),0,param2,0.3086 * (1 - _loc3_),0.6094 * (1 - _loc3_),0.082 * (1 - _loc3_) + _loc3_,0,param2,0,0,0,1,0];
      }
      
      private function setPetMc(param1:MovieClip) : void
      {
         var labels:Array;
         var isMove:Boolean;
         var hasEff:Boolean;
         var frameLabel:FrameLabel = null;
         var p1:int = 0;
         var p2:int = 0;
         var p3:int = 0;
         var p4:int = 0;
         var mc:MovieClip = param1;
         mc.gotoAndStop(1);
         FightMovieManager.instance.addMovie(mc);
         mc.addFrameScript(mc.totalFrames - 1,this.onAttEnd);
         labels = mc.currentLabels;
         isMove = false;
         hasEff = false;
         for each(frameLabel in labels)
         {
            if(frameLabel.name == "eff" && !hasEff)
            {
               hasEff = true;
               FightMovieManager.instance.addMovie(mc);
               mc.addFrameScript(frameLabel.frame - 1,this.onStartEffect);
            }
            else if(frameLabel.name == "move")
            {
               isMove = true;
            }
            else if(frameLabel.name == "shake" && !this.isCriticalHit)
            {
               FightMovieManager.instance.addMovie(mc);
               mc.addFrameScript(frameLabel.frame - 1,this.onStartShEff);
            }
            else if(frameLabel.name == "cri")
            {
               FightMovieManager.instance.addMovie(mc);
               mc.addFrameScript(frameLabel.frame == 1 ? frameLabel.frame : frameLabel.frame - 1,this.onStartCriEff);
            }
            else if(frameLabel.name == "att")
            {
               FightMovieManager.instance.addMovie(mc);
               mc.addFrameScript(frameLabel.frame - 1,this.onStartAttEff);
            }
         }
         if(!hasEff)
         {
            FightMovieManager.instance.addMovie(mc);
            mc.addFrameScript(mc.totalFrames - 2,this.onStartEffect);
         }
         if(isMove)
         {
            p1 = this.getLabelFrame("p1",labels);
            p2 = this.getLabelFrame("p2",labels);
            p3 = this.getLabelFrame("p3",labels);
            p4 = this.getLabelFrame("p4",labels);
            FightMovieManager.instance.addMovie(mc);
            mc.addFrameScript(p1 - 1,function():*
            {
               setPetTowards(mc,p2 - p1);
            });
            mc.addFrameScript(p3 - 1,function():*
            {
               setPetBackwards(mc,p4 - p3);
            });
         }
         mc.gotoAndPlay(1);
      }
      
      private function getLabelFrame(param1:String, param2:Array) : int
      {
         var _loc3_:FrameLabel = null;
         for each(_loc3_ in param2)
         {
            if(_loc3_.name == param1)
            {
               return _loc3_.frame;
            }
         }
         return 0;
      }
      
      private function setPetTowards(param1:MovieClip, param2:int) : void
      {
         var tweenMax:TweenMax = null;
         var mc:MovieClip = param1;
         var duration:int = param2;
         var myTweenLiteVars:TweenLiteVars = new TweenLiteVars();
         myTweenLiteVars.prop("x",mc.x - (this.atk.x - this.def.x));
         myTweenLiteVars.prop("y",mc.y - (this.atk.y - this.def.y));
         myTweenLiteVars.useFrames(true);
         myTweenLiteVars.onComplete(function():void
         {
            FightTweenMaxManager.instance.removeTweenMax(tweenMax);
         });
         tweenMax = new TweenMax(mc,duration,myTweenLiteVars);
         FightTweenMaxManager.instance.addTweenMax(tweenMax);
      }
      
      private function setPetBackwards(param1:MovieClip, param2:int) : void
      {
         var tweenMax:TweenMax = null;
         var mc:MovieClip = param1;
         var duration:int = param2;
         var myTweenLiteVars:TweenLiteVars = new TweenLiteVars();
         myTweenLiteVars.prop("x",mc.x + (this.atk.x - this.def.x));
         myTweenLiteVars.prop("y",mc.y + (this.atk.y - this.def.y));
         myTweenLiteVars.useFrames(true);
         myTweenLiteVars.onComplete(function():void
         {
            FightTweenMaxManager.instance.removeTweenMax(tweenMax);
         });
         tweenMax = new TweenMax(mc,duration,myTweenLiteVars);
         FightTweenMaxManager.instance.addTweenMax(tweenMax);
      }
      
      private function onStartEffect() : void
      {
         this._isAttack = false;
         this.dispatchEvent(new PetFightEvent(PetFightEvent.START_EFFECT,{}));
      }
      
      private function onStartShEff() : void
      {
         if(DocPetFight.skipBattlePresentation)
         {
            return;
         }
         var _loc1_:int = int(this._pmSvr.getOperationPM(this.flaId % 10000).getMaxCommonEvlution().raceId);
         if(this._gameOptionSvr.isNoFightSkillEffect)
         {
            if(!GQKillBigConfig.isNotPlayAllEffectMv(_loc1_))
            {
               return;
            }
         }
         if(FightData.instance.isPFS3KuangBao)
         {
            return;
         }
         var _loc2_:int = int(this._pmSvr.customData.pmSkillMap.getSkill(this.skillId).getSkillType());
         var _loc3_:int = FightData.instance.getSlotId(this._loacId);
         var _loc4_:PlayerBattleInfo = FightData.instance.playerInfo[_loc3_];
         if(Boolean(PMSkillTypes.isDegeneratorSuperSpiritSkill(_loc2_)) || _loc2_ == PMSkillTypes.DEGENERATOR_YU_KILL_BIG || _loc2_ == PMSkillTypes.DEGENERATOR_SHENQI_KILL_BIG)
         {
            if(!this._pmSvr.customData.pmDataMap.getPM(this.raceId).isDegeneratorPM())
            {
               return;
            }
            if(FightData.instance.isSummonedPlayer(_loc4_))
            {
               return;
            }
            if(!this._pmSvr.customData.pmDataMap.getPM(_loc1_).isDegeneratorPM())
            {
               return;
            }
            this._currentActionMovie.stop();
            this.showDegeneratorMovie();
         }
         else if(Boolean(PMSkillTypes.isXinghuiKillBig(_loc2_)) && this._pmSvr.customData.pmDataMap.getPM(this.raceId).getXinghuiType() != XinghuiPetType.JUEXING)
         {
            if(!this._pmSvr.customData.pmDataMap.getPM(_loc1_).isXinghuiPM() && !this._pmSvr.customData.pmDataMap.getPM(this.raceId).isXinghuiPM())
            {
               return;
            }
            if(FightData.instance.isSummonedPlayer(_loc4_))
            {
               return;
            }
            this._currentActionMovie.stop();
            this.showXinghuiMovie();
         }
         else if(PMSkillTypes.isGQKillBig(_loc2_))
         {
            if(!this._pmSvr.customData.pmDataMap.getPM(_loc1_).isGQPM() && !this._pmSvr.customData.pmDataMap.getPM(this.raceId).isGQPM())
            {
               return;
            }
            if(FightData.instance.isSummonedPlayer(_loc4_))
            {
               return;
            }
            this.showGQKillBigMovie();
         }
         else if(this.isCriticalHit)
         {
            this._currentActionMovie.stop();
            this.showCriEffMovie();
         }
      }
      
      private function onStartCriEff() : void
      {
         var _loc1_:int = int(this._pmSvr.getOperationPM(this.flaId % 10000).getMaxCommonEvlution().raceId);
         if(this._gameOptionSvr.isNoFightSkillEffect)
         {
            if(!GQKillBigConfig.isNotPlayAllEffectMv(_loc1_))
            {
               return;
            }
         }
         if(FightData.instance.isPFS3KuangBao)
         {
            return;
         }
         var _loc2_:int = int(this._pmSvr.customData.pmSkillMap.getSkill(this.skillId).getSkillType());
         var _loc3_:int = FightData.instance.getSlotId(this._loacId);
         var _loc4_:PlayerBattleInfo = FightData.instance.playerInfo[_loc3_];
         if(Boolean(PMSkillTypes.isDegeneratorSuperSpiritSkill(_loc2_)) || _loc2_ == PMSkillTypes.DEGENERATOR_YU_KILL_BIG || _loc2_ == PMSkillTypes.DEGENERATOR_SHENQI_KILL_BIG)
         {
            if(!this._pmSvr.customData.pmDataMap.getPM(this.raceId).isDegeneratorPM())
            {
               return;
            }
            if(FightData.instance.isSummonedPlayer(_loc4_))
            {
               return;
            }
            if(!this._pmSvr.customData.pmDataMap.getPM(_loc1_).isDegeneratorPM())
            {
               return;
            }
            this._currentActionMovie.stop();
            this.showDegeneratorMovie();
         }
         else if(Boolean(PMSkillTypes.isXinghuiKillBig(_loc2_)) && this._pmSvr.customData.pmDataMap.getPM(this.raceId).getXinghuiType() != XinghuiPetType.JUEXING)
         {
            if(!this._pmSvr.customData.pmDataMap.getPM(_loc1_).isXinghuiPM() && !this._pmSvr.customData.pmDataMap.getPM(this.raceId).isXinghuiPM())
            {
               return;
            }
            if(FightData.instance.isSummonedPlayer(_loc4_))
            {
               return;
            }
            this._currentActionMovie.stop();
            this.showXinghuiMovie();
         }
         else if(PMSkillTypes.isGQKillBig(_loc2_))
         {
            if(!this._pmSvr.customData.pmDataMap.getPM(_loc1_).isGQPM() && !this._pmSvr.customData.pmDataMap.getPM(this.raceId).isGQPM())
            {
               return;
            }
            if(FightData.instance.isSummonedPlayer(_loc4_))
            {
               return;
            }
            this.showGQKillBigMovie();
         }
         else if(this.isCriticalHit)
         {
            this._currentActionMovie.stop();
            this.showCriEffMovie();
         }
      }
      
      private function hasXingHuiKillBigMovie() : Boolean
      {
         var _loc1_:int = int(this._pmSvr.getOperationPM(this.flaId % 10000).getMaxCommonEvlution().raceId);
         if(FightResConfig.ExcludeIds.indexOf(_loc1_) != -1)
         {
            return false;
         }
         if(!this._pmSvr.customData.pmDataMap.getPM(_loc1_).isXinghuiPM() && !this._pmSvr.customData.pmDataMap.getPM(this.raceId).isXinghuiPM())
         {
            return false;
         }
         var _loc2_:int = FightData.instance.getSlotId(this._loacId);
         var _loc3_:PlayerBattleInfo = FightData.instance.playerInfo[_loc2_];
         if(this._pmSvr.customData.pmDataMap.getPM(this.raceId).getXinghuiType() != XinghuiPetType.JUEXING)
         {
            return !FightData.instance.isSummonedPlayer(_loc3_);
         }
         return false;
      }
      
      private function hasGQKillBigMovie() : Boolean
      {
         var _loc1_:int = int(this._pmSvr.getOperationPM(this.flaId % 10000).getMaxCommonEvlution().raceId);
         if(FightResConfig.ExcludeIds.indexOf(_loc1_) != -1)
         {
            return false;
         }
         if(!this._pmSvr.customData.pmDataMap.getPM(_loc1_).isGQPM() && !this._pmSvr.customData.pmDataMap.getPM(this.raceId).isGQPM())
         {
            return false;
         }
         var _loc2_:int = FightData.instance.getSlotId(this._loacId);
         var _loc3_:PlayerBattleInfo = FightData.instance.playerInfo[_loc2_];
         return !FightData.instance.isSummonedPlayer(_loc3_);
      }
      
      private function showCriEffMovie() : void
      {
         CriticalMovieHelper.showCriEffMovie(this.raceId,this.isFace,this.flaId % 10000,this,function():*
         {
            _currentActionMovie.play();
         });
      }
      
      private function showDegeneratorMovie() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function getXingHuiKillMovieId() : int
      {
         var _loc1_:int = int(this._pmSvr.getOperationPM(this.flaId % 10000).getMaxCommonEvlution().raceId);
         var _loc2_:PetSkinInfo = this._petSkinDataSvr.getPetSkinInfoBySkinId(this.flaId);
         if(!this._pmSvr.customData.pmDataMap.getPM(this.flaId).isXinghuiPM() && _loc2_ == null)
         {
            _loc1_ = int(this._pmSvr.getOperationPM(this.raceId % 10000).getMaxCommonEvlution().raceId);
         }
         return _loc1_;
      }
      
      private function getGQKillMovieId() : int
      {
         var _loc1_:int = int(this._pmSvr.getOperationPM(this.flaId % 10000).getMaxCommonEvlution().raceId);
         var _loc2_:PetSkinInfo = this._petSkinDataSvr.getPetSkinInfoBySkinId(this.flaId);
         if(!this._pmSvr.customData.pmDataMap.getPM(this.flaId).isGQPM() && _loc2_ == null)
         {
            _loc1_ = int(this._pmSvr.getOperationPM(this.raceId % 10000).getMaxCommonEvlution().raceId);
         }
         return _loc1_;
      }
      
      private function showXinghuiMovie() : void
      {
         var maxFlaId:int = 0;
         var petSkinInfo:PetSkinInfo = null;
         var shaker:ScreenShaker = null;
         maxFlaId = this.getXingHuiKillMovieId();
         petSkinInfo = this._petSkinDataSvr.getPetSkinInfoBySkinId(this.flaId);
         var faceId:int = PetFace.getFaceId(this.isFace);
         if(this._xingHuiKillBigMovieLoader == null)
         {
            this._xingHuiKillBigMovieLoader = new XingHuiKillBigMovieLoader(FightData.instance.applicationDomain);
         }
         this._xingHuiKillBigMovieLoader.loadMovie(maxFlaId,faceId,function(param1:MovieClip, param2:MovieClip = null):*
         {
            /*
             * Decompilation error
             * Code may be obfuscated
             * Tip: You can try enabling "Deobfuscate code" option in Settings
             * Error type: ArrayIndexOutOfBoundsException (null)
             */
            throw new flash.errors.IllegalOperationError("Not decompiled due to error");
         });
      }
      
      private function showGQKillBigMovie() : void
      {
         var faceId:int;
         var type:int;
         var gqYiWeiShengGeSkillParse:GQYiweiShenggeSkillParse;
         var maxFlaId:int = 0;
         var petSkinInfo:PetSkinInfo = null;
         var skillInfo:SkillInfo = null;
         maxFlaId = this.getGQKillMovieId();
         if(this._pmSvr.getOperationPM(maxFlaId).pmData.isXinghuiPM())
         {
            this._currentActionMovie.stop();
            this.showXinghuiMovie();
            return;
         }
         if(this._pmSvr.getOperationPM(maxFlaId).pmData.isDegeneratorPM())
         {
            this._currentActionMovie.stop();
            this.showDegeneratorMovie();
            return;
         }
         petSkinInfo = this._petSkinDataSvr.getPetSkinInfoBySkinId(this.flaId);
         faceId = PetFace.getFaceId(this.isFace);
         if(this._gqKillBigMovieLoader == null)
         {
            this._gqKillBigMovieLoader = new GQKillBigMovieLoader(FightData.instance.applicationDomain);
         }
         ProgressFullSprite.lockScreen();
         type = 0;
         gqYiWeiShengGeSkillParse = GQYiweiShenggeSkillParse.getYiweiShenggeSkillData(this.raceId);
         if(gqYiWeiShengGeSkillParse != null)
         {
            for each(skillInfo in this._pbi.skills)
            {
               if(skillInfo.id == gqYiWeiShengGeSkillParse.getKillBigId())
               {
                  type = 1;
                  break;
               }
            }
         }
         this._gqKillBigMovieLoader.loadMovie(maxFlaId,this.raceId,faceId,function(param1:MovieClip, param2:MovieClip = null):*
         {
            /*
             * Decompilation error
             * Code may be obfuscated
             * Tip: You can try enabling "Deobfuscate code" option in Settings
             * Error type: ArrayIndexOutOfBoundsException (null)
             */
            throw new flash.errors.IllegalOperationError("Not decompiled due to error");
         },-1,true,type);
      }
      
      public function playMusic(param1:Boolean, param2:String) : void
      {
         XingHuiKillBigMovieLoader.playMusic(this.flaId,param1,param2,FightData.instance.applicationDomain);
      }
      
      private function getScaleRate() : Number
      {
         return FightData.instance.getPetVisionScale();
      }
      
      private function onStartAttEff() : void
      {
         this.dispatchEvent(new PetFightEvent(PetFightEvent.START_DEFEND));
      }
      
      private function onAttEnd() : void
      {
         this.setNormal();
         if(this.onAttackEnd != null)
         {
            this.onAttackEnd.apply();
         }
         this.onAttackEnd = null;
      }
      
      public function setHurt(param1:Boolean, param2:Boolean = false, param3:Boolean = true) : void
      {
         var frame:int = 0;
         var initP:Point = null;
         var p:Point = null;
         var mc:MovieClip = null;
         var labels:Array = null;
         var frameLabel:FrameLabel = null;
         var isMiss:Boolean = param1;
         var isCriticalHit:Boolean = param2;
         var isShowEffect:Boolean = param3;
         if(this._isAttack)
         {
            return;
         }
         if(this.onAttackEnd != null)
         {
            this.onAttackEnd.apply();
            this.onAttackEnd = null;
         }
         this._isDefending = isMiss;
         if(isMiss)
         {
            frame = PetActionFrame.FRAME_STAND;
            if(isShowEffect)
            {
               this.filters = [new BlurFilter(16,4,BitmapFilterQuality.LOW)];
               initP = PositionUtil.getDefaultPosition(this._loacId);
               p = PositionUtil.getDefendPosition(this._loacId);
               MoveUtil.move(this,initP.x,initP.y,p.x,p.y,function(param1:Function):void
               {
                  filters = null;
                  param1.apply();
               });
            }
         }
         else
         {
            frame = PetActionFrame.FRAME_DEFEND;
         }
         this.playAction(frame);
         if(frame == PetActionFrame.FRAME_DEFEND)
         {
            if(isShowEffect)
            {
               labels = this._currentActionMovie.currentLabels;
               for each(frameLabel in labels)
               {
                  if(frameLabel.name == "hurt")
                  {
                     FightMovieManager.instance.addMovie(this._currentActionMovie);
                     this._currentActionMovie.addFrameScript(frameLabel.frame == 1 ? frameLabel.frame : frameLabel.frame - 1,function():void
                     {
                        onAddHurtEff(isCriticalHit);
                     });
                  }
               }
            }
            mc = this._currentActionMovie;
            FightMovieManager.instance.addMovie(this._currentActionMovie);
            this._currentActionMovie.addFrameScript(this._currentActionMovie.totalFrames - 1,function():*
            {
               if(mc == _currentActionMovie)
               {
                  setNormal();
               }
               else
               {
                  FightMovieManager.instance.removeMovie(mc);
                  mc.stop();
               }
            });
            this._currentActionMovie.gotoAndPlay(1);
            if(this._gqShenBingEffecthelper)
            {
               this._gqShenBingEffecthelper.hurt();
            }
         }
         if(!FightData.instance.isLowQuality)
         {
            this.playSmokeMovie();
         }
         if(frame == PetActionFrame.FRAME_DEFEND && StatusUtil.getIsHasXingYunBuff(this._pbi))
         {
            this.playXingYunMovie();
         }
      }
      
      private function playSmokeMovie() : void
      {
         var mcSmoke:MovieClip = null;
         var childIndex:int = 0;
         var player:PlayerBattleInfo = FightData.instance.playerInfo[this.slotId];
         if(player != null && player.myPets != null && player.myPets.length > 0 && (player.myPets[0] as PetBriefInfo).curHp > 0)
         {
            if(this.isFace)
            {
               mcSmoke = new SmokeMovie_Positive();
            }
            else
            {
               mcSmoke = new SmokeMovie_Back();
            }
            mcSmoke.scaleX = this.getScaleRate();
            mcSmoke.scaleY = this.getScaleRate();
            FightMovieManager.instance.addMovie(mcSmoke);
            mcSmoke.addFrameScript(mcSmoke.totalFrames - 1,function():void
            {
               FightMovieManager.instance.removeMovie(mcSmoke);
               mcSmoke.stop();
               DisplayUtil.stopAndRemove(mcSmoke);
            });
            mcSmoke.gotoAndPlay(1);
            childIndex = this.numChildren > 1 ? this.numChildren - 1 : 0;
            this.addChildAt(mcSmoke,childIndex);
         }
      }
      
      private function onAddHurtEff(param1:Boolean) : void
      {
         var mc:MovieClip = null;
         var hurtMvKey:String = null;
         var count:int = 0;
         var defaultPoint:Point = null;
         var defaultX:Number = NaN;
         var defaultY:Number = NaN;
         var colorCount:int = 0;
         var defaultTF:ColorTransform = null;
         var isCriticalHit:Boolean = param1;
         if(GQPetHelper.checkIsGQPet(this.raceId))
         {
            hurtMvKey = FightMcKeys.GQHurtMovie;
            mc = FightMcPool.instance.getMcByKey(hurtMvKey);
            if(mc == null)
            {
               mc = new GQHurtMovie() as MovieClip;
            }
         }
         else
         {
            hurtMvKey = FightMcKeys.HurtMovie;
            mc = FightMcPool.instance.getMcByKey(hurtMvKey);
            if(mc == null)
            {
               mc = new HurtMovie() as MovieClip;
            }
         }
         mc.scaleX = this.getScaleRate();
         mc.scaleY = this.getScaleRate();
         mc.scaleX *= this.isFace ? 1 : -1;
         FightMovieManager.instance.addMovie(mc);
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(mc);
            mc.stop();
            FightMcPool.instance.pushMcByKey(hurtMvKey,mc);
         });
         this.addChild(mc);
         mc.gotoAndPlay(1);
         count = 0;
         defaultPoint = PositionUtil.getDefaultPosition(this._loacId);
         defaultX = this.x;
         defaultY = this.y;
         TimerUtil.useTimer(1,10,function():void
         {
            ++count;
            if(count < 10)
            {
               x = defaultX + (Math.random() * 2 - 1) * 10;
               y = defaultY + (Math.random() * 2 - 1) * 10;
            }
            else
            {
               x = defaultPoint.x;
               y = defaultPoint.y;
            }
         });
         colorCount = 0;
         defaultTF = transform.colorTransform;
         TimerUtil.useTimer(1,10,function():void
         {
            ++colorCount;
            transform.colorTransform = colorCount % 2 == 1 ? new ColorTransform(1,1,1,0.9,255) : defaultTF;
         });
         if(isCriticalHit)
         {
            FightController.instance.fightPanel.shake();
         }
      }
      
      public function addListen(param1:int, param2:Boolean = false) : void
      {
         if(this._mouseResponder == null || this._currentActionMovie == null)
         {
            return;
         }
         this.slotId = param1;
         this.addEventListener(MouseEvent.CLICK,this.onClickPet,true);
         this._mouseResponder.addEventListener(MouseEvent.CLICK,this.onClickPet);
         this._mouseResponder.addEventListener(MouseEvent.ROLL_OVER,this.onMouseOverPet2);
         this._mouseResponder.addEventListener(MouseEvent.ROLL_OUT,this.onMouseOutPet2);
         this._currentActionMovie.addEventListener(MouseEvent.ROLL_OVER,this.onMouseOverPet2);
         this._currentActionMovie.addEventListener(MouseEvent.ROLL_OUT,this.onMouseOutPet2);
         ChangeMouse.instance.change(param2);
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(PetFightEvent.Fight4v4StartSelectEvent,{
            "start":true,
            "slot":param1
         }));
      }
      
      private function onMouseOutPet2(param1:Event) : void
      {
         this.clearGlow();
      }
      
      private function onMouseOverPet2(param1:Event) : void
      {
         this.applayGlow();
      }
      
      private function applayGlow() : void
      {
         var _loc1_:Number = 16776960;
         var _loc2_:Number = 1;
         var _loc3_:Number = 8;
         var _loc4_:Number = 8;
         var _loc5_:Number = 2;
         var _loc6_:Boolean = false;
         var _loc7_:Boolean = false;
         var _loc8_:Number = BitmapFilterQuality.LOW;
         var _loc9_:GlowFilter = new GlowFilter(_loc1_,_loc2_,_loc3_,_loc4_,_loc5_,_loc8_,_loc6_,_loc7_);
         var _loc10_:Array = [];
         _loc10_.push(_loc9_);
         this._currentActionMovie.filters = _loc10_;
      }
      
      private function clearGlow() : void
      {
         if(this._currentActionMovie)
         {
            this._currentActionMovie.filters = null;
         }
      }
      
      private function onClickPet(param1:MouseEvent) : *
      {
         if(StatusUtil.getIsInLockByJueduiWeiduState(this._pbi))
         {
            return;
         }
         FightData.instance.targetSlot = this.slotId;
         this.removeListen();
         FightEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CLICK_SKILL,{"haveHit":true}));
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent(PetFightEvent.CLICK_SKILL,{}));
      }
      
      public function removeListen() : void
      {
         ChangeMouse.instance.revert();
         this.removeEventListener(Event.REMOVED_FROM_STAGE,this.onPetRemove);
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAddedPet);
         this.removeEventListener(MouseEvent.CLICK,this.onClickPet,true);
         if(this._mouseResponder)
         {
            this._mouseResponder.removeEventListener(MouseEvent.CLICK,this.onClickPet);
            this._mouseResponder.removeEventListener(MouseEvent.ROLL_OVER,this.onMouseOverPet2);
            this._mouseResponder.removeEventListener(MouseEvent.ROLL_OUT,this.onMouseOutPet2);
         }
         if(this._currentActionMovie)
         {
            this._currentActionMovie.removeEventListener(MouseEvent.ROLL_OVER,this.onMouseOverPet2);
            this._currentActionMovie.removeEventListener(MouseEvent.ROLL_OUT,this.onMouseOutPet2);
         }
         this.clearGlow();
      }
      
      public function addStopMovie(param1:int) : void
      {
         if(this.stopMovie == null)
         {
            this.stopMovie = FightMcPool.instance.getRes(StopMovie,true);
         }
         var _loc2_:int = this.numChildren > 1 ? this.numChildren - 1 : 0;
         this.addChildAt(this.stopMovie,_loc2_);
         this.stopMovie.gotoAndStop(param1 + 1);
      }
      
      public function removeStopMovie() : void
      {
         if(this.stopMovie != null && this.contains(this.stopMovie))
         {
            FightMcPool.instance.recycle(this.stopMovie);
            this.stopMovie = null;
         }
      }
      
      public function dispose() : void
      {
         DocPetFight.noteDiagnosticAttackDisposed(this);
         this.removeListen();
         this.disposeMouseTouchPetListener();
         this.disposeMouseResponder();
         if(this._movieStrategy)
         {
            this._movieStrategy.dispose();
            this._movieStrategy = null;
         }
         if(this._downLightBitmap != null)
         {
            this._downLightBitmap.dispose();
            this._downLightBitmap = null;
         }
         if(this._upLightBitmap != null)
         {
            this._upLightBitmap.dispose();
            this._upLightBitmap = null;
         }
         if(this._currentActionMovie != null && this._currentActionMovie is SyncBitmapMovieClip)
         {
            this._currentActionMovie.dispose();
            this._currentActionMovie = null;
         }
         this.talkable && this.talkable.dispose();
         this.talkable = null;
         this.removeSysEffectCtrl();
         DisplayUtil.stopAndRemove(this._myMark);
         this._myMark = null;
         this.onAttackEnd = null;
         this._setPetVisible = null;
      }
      
      private function playAction(param1:int) : void
      {
         if(this._needSwitch)
         {
            return;
         }
         if(this._currentFrame == param1)
         {
            return;
         }
         if(this._movieStrategy == null)
         {
            return;
         }
         this.removeStopMovie();
         var _loc2_:MovieClip = this._movieStrategy.getActionMovie(param1);
         if(_loc2_ == null)
         {
            if(param1 != PetActionFrame.FRAME_STAND)
            {
               this.setNormal();
            }
            return;
         }
         this._currentFrame = param1;
         FightMovieManager.instance.removeMovie(this._currentActionMovie);
         DisplayUtil.stopAndRemove(this._currentActionMovie);
         this._currentActionMovie = _loc2_;
         var _loc3_:int = this.numChildren > 1 ? this.numChildren - 1 : 0;
         this.addChildAt(this._currentActionMovie,_loc3_);
         this._currentActionMovie.play();
         this.callFrameScript(param1);
      }
      
      private function callFrameScript(param1:int) : void
      {
         if(param1 == PetActionFrame.FRAME_SPECIAL_ATT || param1 == PetActionFrame.FRAME_PHRYSICAL_ATT || param1 == PetActionFrame.FRAME_ATTRIBUTE_ATT || param1 == PetActionFrame.FRAME_LEGEND_BIG || param1 == PetActionFrame.FRAME_ATTRIBUTE_ATT_OLD || param1 == PetActionFrame.FRAME_DEGENERATOR_XIAN_APPEAR || param1 == PetActionFrame.FRAME_ZHUANGSHU_ATT)
         {
            this.onEnterAttFrame();
         }
      }
      
      private function removeSysEffectCtrl() : void
      {
         if(this._shenLingEffEctCtrl)
         {
            this._shenLingEffEctCtrl.dispose();
            this._shenLingEffEctCtrl = null;
         }
         if(this._annualFee22EffEctCtrl)
         {
            this._annualFee22EffEctCtrl.dispose();
            this._annualFee22EffEctCtrl = null;
         }
         if(this._gqGuangjinEffectHelper)
         {
            this._gqGuangjinEffectHelper.dispose();
            this._gqGuangjinEffectHelper = null;
         }
         if(this._gqShenBingEffecthelper)
         {
            this._gqShenBingEffecthelper.dispose();
            this._gqShenBingEffecthelper = null;
         }
         if(this._gqTianyiEffectHelper)
         {
            this._gqTianyiEffectHelper.dispose();
            this._gqTianyiEffectHelper = null;
         }
         if(this._yanhuaZhiyaoEffectHelper)
         {
            this._yanhuaZhiyaoEffectHelper.dispose();
            this._yanhuaZhiyaoEffectHelper = null;
         }
         if(this._mingYunBoYiEffectHelper)
         {
            this._mingYunBoYiEffectHelper.dispose();
            this._mingYunBoYiEffectHelper = null;
         }
         if(this._huanLingShiEffecthelper)
         {
            this._huanLingShiEffecthelper.dispose();
            this._huanLingShiEffecthelper = null;
         }
         this._isLoading = false;
      }
      
      public function isLoading() : Boolean
      {
         return this._isLoading;
      }
      
      public function getCurPbi() : PetBriefInfo
      {
         return this._pbi;
      }
      
      private function playXingYunMovie() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
   }
}

